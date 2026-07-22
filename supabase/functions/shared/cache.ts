/**
 * ═══════════════════════════════════════════════════════════════════════════
 * cache.ts — Request-Level Response Caching (Postgres-backed)
 * Location: supabase/functions/shared/cache.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * If a teacher generates "JEE Physics Kinematics Medium 10 Questions" twice,
 * the second call should return instantly without calling OpenRouter.
 * This saves cost, reduces latency, and improves user experience.
 *
 * CACHE STRATEGY: Content-Addressed Deterministic Cache
 * ──────────────────────────────────────────────────────
 * Cache Key = SHA-256 hash of (feature + exam + subject + chapter + difficulty + count)
 *
 * Same inputs → same hash → same cached response
 *
 * We hash the inputs because:
 * 1. Consistent key format regardless of order
 * 2. Short, fixed-length key (32 bytes) regardless of input length
 * 3. Cannot reverse-engineer the original inputs from the hash
 *    (cache table doesn't expose sensitive prompt details)
 *
 * WHY NOT REDIS / EDGE CACHE?
 * ────────────────────────────
 * - Redis: Not part of your stack (additional cost/complexity)
 * - Edge Cache (Cloudflare/Supabase CDN): Works for GET requests,
 *   not POST requests with bodies
 * - Postgres: Already in your stack, gives you queryable cache with TTL
 *
 * CACHE INVALIDATION
 * ───────────────────
 * Entries expire after CACHE_CONFIG.defaultTtlSeconds (1 hour by default).
 * A Postgres scheduled job or cron function can purge expired entries:
 *   DELETE FROM ai_cache WHERE expires_at < NOW();
 *
 * WHAT IS CACHED
 * ──────────────
 * Only deterministic features: DPP, BPP, Explanation, Notes.
 * NOT cached: Chat (every conversation is unique), doubt-solver (personal)
 *
 * CACHE HIT RATE EXPECTATIONS
 * ────────────────────────────
 * In a class of 30 students doing the same chapter, the SECOND student
 * gets the cached DPP instantly. Students 3-30 all get it from cache.
 * This turns 30 API calls into 1 — 97% cost reduction for popular topics.
 *
 * DATABASE SCHEMA
 * ────────────────
 * Table: ai_cache
 *   id           UUID     PRIMARY KEY
 *   cache_key    TEXT     UNIQUE NOT NULL  (SHA-256 hex hash)
 *   feature      TEXT     NOT NULL
 *   response     JSONB    NOT NULL         (the cached AI response)
 *   hit_count    INTEGER  DEFAULT 0        (how many times this was returned from cache)
 *   created_at   TIMESTAMPTZ DEFAULT NOW()
 *   expires_at   TIMESTAMPTZ NOT NULL
 *
 * Index: (cache_key) — for fast lookups
 * Index: (expires_at) — for efficient TTL cleanup
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { CACHE_CONFIG } from "./config.ts";
import { Logger } from "./logger.ts";

// ── Cache key generation ────────────────────────────────────────────────────

/**
 * Generates a deterministic cache key from the request parameters.
 *
 * Algorithm:
 * 1. Combine all relevant parameters into a canonical string
 * 2. Hash with SHA-256 (available natively in Deno via crypto.subtle)
 * 3. Return hex-encoded hash
 *
 * WHY SHA-256 NOT MD5?
 * ─────────────────────
 * MD5 has known collisions (two different inputs producing the same hash).
 * SHA-256 is collision-resistant — different inputs almost certainly produce
 * different hashes. This prevents false cache hits.
 *
 * @param feature - Feature name
 * @param params  - Request parameters that determine uniqueness
 */
export async function generateCacheKey(
  feature: string,
  params: Record<string, unknown>
): Promise<string> {
  // Canonical string: sorted keys + values, lowercased, comma-separated
  const canonical = [
    feature,
    ...Object.entries(params)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([k, v]) => `${k}:${JSON.stringify(v)}`)
  ]
    .join("|")
    .toLowerCase();

  // Hash using Web Crypto API (available in Deno Edge Runtime)
  const encoder = new TextEncoder();
  const data = encoder.encode(canonical);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);

  // Convert ArrayBuffer to hex string
  const hashArray  = Array.from(new Uint8Array(hashBuffer));
  const hashHex    = hashArray.map(b => b.toString(16).padStart(2, "0")).join("");

  return hashHex;
}

// ── Cache operations ────────────────────────────────────────────────────────

/**
 * Attempts to retrieve a cached response.
 *
 * CACHE MISS: Returns null → caller proceeds with fresh AI call
 * CACHE HIT:  Returns the cached response → AI call is skipped
 *
 * SECURITY NOTE
 * ──────────────
 * We only cache the RESPONSE (AI-generated content), never the prompts.
 * This means if someone queries the cache table, they don't see:
 * - System prompts (our proprietary templates)
 * - Teacher instructions
 * - Full prompt text
 *
 * @param adminClient - Service-role client for cache table access
 * @param cacheKey    - SHA-256 hash of the request parameters
 * @param feature     - Feature name (for logging)
 * @param log         - Logger instance
 * @returns           - Cached data or null
 */
export async function getCachedResponse(
  adminClient: SupabaseClient,
  cacheKey: string,
  feature: string,
  log: Logger
): Promise<Record<string, unknown> | null> {
  // Return null immediately if caching is disabled or feature isn't cacheable
  if (!CACHE_CONFIG.enabled || !CACHE_CONFIG.cacheableFeatures.includes(feature)) {
    return null;
  }

  try {
    const { data, error } = await adminClient
      .from("ai_cache")
      .select("response, hit_count, expires_at")
      .eq("cache_key", cacheKey)
      .single();

    if (error || !data) {
      log.debug("Cache miss", { feature, cacheKey: cacheKey.slice(0, 8) + "..." });
      return null;
    }

    // Check TTL: if expired, treat as miss (cleanup runs separately)
    if (new Date(data.expires_at) < new Date()) {
      log.debug("Cache expired", { feature, cacheKey: cacheKey.slice(0, 8) + "..." });
      return null;
    }

    // Increment hit counter (fire-and-forget, non-blocking)
    adminClient
      .from("ai_cache")
      .update({ hit_count: (data.hit_count ?? 0) + 1 })
      .eq("cache_key", cacheKey)
      .then()
      .catch(() => {}); // Never block on this

    log.info("Cache HIT", {
      feature,
      cacheKey: cacheKey.slice(0, 8) + "...",
      hitCount: data.hit_count + 1,
    });

    return data.response as Record<string, unknown>;
  } catch (err) {
    // Cache failure is non-fatal — fall through to fresh AI call
    log.warn("Cache read failed (non-fatal, will generate fresh)", { err: String(err) });
    return null;
  }
}

/**
 * Stores a response in the cache.
 *
 * Called AFTER a successful AI call (not on failures — we never cache errors).
 *
 * Uses upsert (INSERT ... ON CONFLICT DO UPDATE) so if two requests arrive
 * simultaneously, the last one wins (idempotent).
 *
 * @param adminClient - Service-role client
 * @param cacheKey    - SHA-256 hash of the request
 * @param feature     - Feature name
 * @param response    - The AI response to cache
 * @param ttlSeconds  - How long to cache (defaults to config)
 * @param log         - Logger instance
 */
export async function setCachedResponse(
  adminClient: SupabaseClient,
  cacheKey: string,
  feature: string,
  response: Record<string, unknown>,
  log: Logger,
  ttlSeconds: number = CACHE_CONFIG.defaultTtlSeconds
): Promise<void> {
  // Don't cache if disabled or feature isn't cacheable
  if (!CACHE_CONFIG.enabled || !CACHE_CONFIG.cacheableFeatures.includes(feature)) {
    return;
  }

  // Don't cache very large responses (DB bloat prevention)
  const responseStr = JSON.stringify(response);
  if (responseStr.length > CACHE_CONFIG.maxCachedResponseLength) {
    log.debug("Response too large to cache", { feature, length: responseStr.length });
    return;
  }

  const expiresAt = new Date(Date.now() + ttlSeconds * 1000).toISOString();

  try {
    const { error } = await adminClient
      .from("ai_cache")
      .upsert(
        {
          cache_key:  cacheKey,
          feature,
          response,
          hit_count:  0,
          expires_at: expiresAt,
        },
        { onConflict: "cache_key" }  // Update if key already exists
      );

    if (error) {
      log.warn("Cache write failed (non-fatal)", { error: error.message });
    } else {
      log.debug("Response cached", {
        feature,
        cacheKey: cacheKey.slice(0, 8) + "...",
        ttlSeconds,
        expiresAt,
      });
    }
  } catch (err) {
    // Never block the main flow on cache failures
    log.warn("Cache write threw (non-fatal)", { err: String(err) });
  }
}

/**
 * Purges all expired cache entries.
 * Call this from a scheduled Edge Function (cron job) daily.
 *
 * Usage:
 *   await purgeExpiredCache(adminClient, log);
 */
export async function purgeExpiredCache(
  adminClient: SupabaseClient,
  log: Logger
): Promise<number> {
  try {
    const { count, error } = await adminClient
      .from("ai_cache")
      .delete({ count: "exact" })
      .lt("expires_at", new Date().toISOString());

    if (error) {
      log.error("Cache purge failed", error);
      return 0;
    }

    const purged = count ?? 0;
    log.info("Cache purge complete", { purgedEntries: purged });
    return purged;
  } catch (err) {
    log.error("Cache purge threw unexpected error", err);
    return 0;
  }
}

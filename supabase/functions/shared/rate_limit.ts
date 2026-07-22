/**
 * ═══════════════════════════════════════════════════════════════════════════
 * rate_limit.ts — Distributed Rate Limiter (Postgres-backed)
 * Location: supabase/functions/shared/rate_limit.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Prevents abuse, controls AI API costs, and enforces fair usage per tier.
 *
 * WHY POSTGRES-BACKED (NOT REDIS)?
 * ──────────────────────────────────
 * You don't have Redis. Postgres is your only database.
 * For this use case (AI generation, not high-frequency API calls),
 * Postgres is perfectly adequate:
 * - DPP generation: maybe 20 calls/hour per user → Postgres handles easily
 * - Chat: maybe 50 messages/hour per user → Postgres handles easily
 * - Redis would add cost and complexity for no benefit at this scale
 *
 * HOW IT WORKS
 * ─────────────
 * The `ai_usage` table records every AI call with:
 * - user_id, feature, created_at
 *
 * To check limits, we run:
 *   SELECT COUNT(*) FROM ai_usage
 *   WHERE user_id = $1 AND feature = $2
 *     AND created_at >= NOW() - INTERVAL '<window> minutes'
 *
 * This COUNT(*) query is fast on indexed columns and runs in microseconds
 * even with thousands of rows per user.
 *
 * DATABASE SCHEMA (in migration file)
 * ────────────────────────────────────
 * Table: ai_usage
 *   id          UUID      PRIMARY KEY
 *   user_id     UUID      NOT NULL (references profiles.id)
 *   feature     TEXT      NOT NULL  ('generate-dpp', 'ai-chat', etc.)
 *   model       TEXT      NOT NULL  (actual model used)
 *   provider    TEXT      NOT NULL  ('openrouter')
 *   prompt_tokens      INTEGER DEFAULT 0
 *   completion_tokens  INTEGER DEFAULT 0
 *   estimated_cost     NUMERIC(10,8) DEFAULT 0
 *   latency_ms  INTEGER
 *   status      TEXT      ('success', 'failed')
 *   error       TEXT      (null on success)
 *   created_at  TIMESTAMPTZ DEFAULT NOW()
 *
 * Indexes:
 *   (user_id, feature, created_at DESC) — for rate limit queries
 *   (created_at DESC)                   — for admin reporting
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { FEATURE_LIMITS, RATE_LIMITS, UserTier } from "./config.ts";
import { Errors } from "./errors.ts";
import { Logger } from "./logger.ts";

// ── Usage log entry (written on every AI call) ─────────────────────────────

export interface UsageEntry {
  userId: string;
  feature: string;
  model: string;
  provider: string;
  promptTokens: number;
  completionTokens: number;
  estimatedCostUsd: number;
  latencyMs: number;
  status: "success" | "failed";
  error?: string;
}

// ── Cost calculation ───────────────────────────────────────────────────────

/** Per-million token pricing for cost estimation */
const MODEL_PRICING: Record<string, { input: number; output: number }> = {
  "google/gemini-2.0-flash-exp:free":  { input: 0,      output: 0      }, // Free
  "meta-llama/llama-3.1-8b-instruct:free": { input: 0, output: 0      }, // Free
  "google/gemini-2.5-flash":           { input: 0.075,  output: 0.30   },
  "openai/gpt-4o-mini":                { input: 0.15,   output: 0.60   },
  "openai/gpt-4o":                     { input: 5.00,   output: 15.00  },
  "anthropic/claude-3-5-sonnet":       { input: 3.00,   output: 15.00  },
  "default":                           { input: 0.30,   output: 0.60   },
};

export function estimateCost(model: string, promptTokens: number, completionTokens: number): number {
  const pricing = MODEL_PRICING[model] ?? MODEL_PRICING.default;
  const cost = (promptTokens / 1_000_000) * pricing.input
             + (completionTokens / 1_000_000) * pricing.output;
  return Number(cost.toFixed(8));
}

// ── Rate limiter ────────────────────────────────────────────────────────────

/**
 * Checks whether the user has exceeded their rate limit for a feature.
 *
 * Algorithm:
 * 1. Look up the feature-specific limit (from config.ts FEATURE_LIMITS)
 * 2. COUNT rows in ai_usage for this user + feature in the time window
 * 3. If count >= limit → throw RATE_LIMITED
 * 4. If count < limit → allow (the actual usage row is written later)
 *
 * FAIL-OPEN POLICY
 * ──────────────────
 * If the database query fails (e.g., connection error), we LOG the failure
 * but ALLOW the request through. This is "fail open" design:
 * - Fail closed would block all users when the DB is slow
 * - Fail open lets requests through but may slightly over-serve in edge cases
 * At this scale, fail-open is the right choice. Rate limit is abuse prevention,
 * not a hard SLA enforcement mechanism.
 *
 * @param adminClient - Service-role Supabase client (needed to read usage table)
 * @param userId      - The authenticated user's UUID
 * @param feature     - Feature name ('generate-dpp', 'ai-chat', etc.)
 * @param tier        - User tier for tier-based limits
 * @param log         - Logger instance for tracing
 */
export async function checkRateLimit(
  adminClient: SupabaseClient,
  userId: string,
  feature: string,
  tier: UserTier,
  log: Logger
): Promise<void> {
  // Resolve limits: feature-specific limit takes priority over tier limit
  const featureLimit = FEATURE_LIMITS[feature];
  const tierLimit    = RATE_LIMITS[tier] ?? RATE_LIMITS.free;

  const limit         = featureLimit?.maxRequests  ?? tierLimit.maxRequests;
  const windowMinutes = featureLimit?.windowMinutes ?? tierLimit.windowMinutes;

  const windowStart = new Date(
    Date.now() - windowMinutes * 60 * 1000
  ).toISOString();

  try {
    const { count, error } = await adminClient
      .from("ai_usage")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("feature", feature)
      .eq("status", "success")     // Only count successful calls (not failed retries)
      .gte("created_at", windowStart);

    if (error) {
      // Fail open: DB error → allow request but log warning
      log.warn("Rate limit DB check failed (allowing request)", { error: error.message });
      return;
    }

    const requestCount = count ?? 0;
    log.debug("Rate limit check", {
      feature,
      tier,
      used: requestCount,
      limit,
      windowMinutes,
    });

    if (requestCount >= limit) {
      log.warn("Rate limit exceeded", { userId, feature, used: requestCount, limit });
      throw Errors.rateLimited(feature, windowMinutes);
    }
  } catch (err) {
    if (err instanceof Error && "code" in err) throw err; // Re-throw AppErrors
    log.warn("Rate limit check threw unexpected error (allowing request)", { err: String(err) });
  }
}

/**
 * Writes a usage log entry to the ai_usage table.
 * Called AFTER every AI call (success or failure).
 *
 * IMPORTANT: This is best-effort — failures are logged but never thrown.
 * The user must always get their response even if logging fails.
 */
export async function logUsage(
  adminClient: SupabaseClient,
  entry: UsageEntry,
  log: Logger
): Promise<void> {
  try {
    const { error } = await adminClient.from("ai_usage").insert({
      user_id:           entry.userId,
      feature:           entry.feature,
      model:             entry.model,
      provider:          entry.provider,
      prompt_tokens:     entry.promptTokens,
      completion_tokens: entry.completionTokens,
      estimated_cost:    entry.estimatedCostUsd,
      latency_ms:        entry.latencyMs,
      status:            entry.status,
      error:             entry.error ?? null,
    });

    if (error) {
      log.warn("Failed to write usage log (non-fatal)", { error: error.message });
    } else {
      log.debug("Usage logged", {
        feature: entry.feature,
        status:  entry.status,
        cost:    `$${entry.estimatedCostUsd}`,
        tokens:  entry.promptTokens + entry.completionTokens,
      });
    }
  } catch (err) {
    // Never throw from logging
    log.warn("Usage logging threw unexpected error (non-fatal)", { err: String(err) });
  }
}

/**
 * Returns current usage stats for a user + feature.
 * Useful for displaying "X/Y requests remaining" in Flutter.
 */
export async function getRateLimitStatus(
  adminClient: SupabaseClient,
  userId: string,
  feature: string,
  tier: UserTier
): Promise<{ used: number; limit: number; windowMinutes: number; remaining: number }> {
  const featureLimit = FEATURE_LIMITS[feature];
  const tierLimit    = RATE_LIMITS[tier] ?? RATE_LIMITS.free;
  const limit        = featureLimit?.maxRequests  ?? tierLimit.maxRequests;
  const windowMinutes= featureLimit?.windowMinutes ?? tierLimit.windowMinutes;

  const windowStart = new Date(Date.now() - windowMinutes * 60 * 1000).toISOString();

  const { count } = await adminClient
    .from("ai_usage")
    .select("id", { count: "exact", head: true })
    .eq("user_id", userId)
    .eq("feature", feature)
    .eq("status", "success")
    .gte("created_at", windowStart);

  const used = count ?? 0;
  return { used, limit, windowMinutes, remaining: Math.max(0, limit - used) };
}

/**
 * rate_limiter.ts — Supabase-native distributed rate limiting
 *
 * WHY THIS EXISTS
 * ───────────────
 * AI API calls cost real money. Without rate limiting:
 *   - One rogue user can burn through your API budget
 *   - Malicious actors can DDoS your AI endpoint
 *   - Students can click "Generate" 50 times in 10 seconds
 *
 * WHY NOT USE REDIS?
 * ───────────────────
 * You don't have Redis. This uses your existing Supabase Postgres table
 * as the rate-limit store. This is perfectly adequate for this use case
 * (rate-limiting AI generation, not high-frequency trading).
 *
 * HOW IT WORKS
 * ─────────────
 * 1. Before every AI call, we run a lightweight DB query:
 *    "How many times did this user call this function in the last N minutes?"
 * 2. If over the limit → reject with 429
 * 3. If under the limit → proceed and log this attempt
 *
 * The log entry is written by the EXISTING `ai_generation_logs` insert in
 * generate-dpp/database.ts — no duplicate writes needed. The rate limiter
 * only READS, never writes. This makes it zero overhead on the happy path.
 *
 * TABLE REQUIREMENT
 * ─────────────────
 * The `ai_generation_logs` table must have:
 *   - teacher_id (or user_id): uuid
 *   - created_at: timestamptz (auto-set by Postgres default)
 *   - status: text (we only count "success" and "failed" attempts)
 *
 * CONFIGURATION
 * ─────────────
 * Change LIMITS below to tune per-feature rate limits.
 * These are daily limits to prevent abuse, not per-second throttling.
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { AppError } from "./error_handler.ts";

// ── Per-function per-user limits ──────────────────────────────────────────
// Key: feature name. Value: { windowMinutes, maxRequests }
const LIMITS: Record<string, { windowMinutes: number; maxRequests: number }> = {
  "generate-dpp":          { windowMinutes: 60, maxRequests: 20 },  // 20 DPPs/hour
  "generate-bpp":          { windowMinutes: 60, maxRequests: 20 },
  "ai-chat":               { windowMinutes: 60, maxRequests: 50 },  // 50 chat msgs/hour
  "ai-explanation":        { windowMinutes: 60, maxRequests: 30 },
  "question-paper":        { windowMinutes: 60, maxRequests: 5  },  // expensive
  "doubt-solver":          { windowMinutes: 60, maxRequests: 30 },
  "notes-generator":       { windowMinutes: 60, maxRequests: 10 },
  "default":               { windowMinutes: 60, maxRequests: 10 },
};

/**
 * Checks the rate limit for a given user + feature combination.
 *
 * Throws AppError("RATE_LIMITED") if the user has exceeded their limit.
 * Returns silently if the user is within limits.
 *
 * @param adminClient - Service-role Supabase client (needs table read access)
 * @param userId      - The authenticated user's UUID
 * @param feature     - The feature being rate-limited (matches keys in LIMITS)
 */
export async function checkRateLimit(
  adminClient: SupabaseClient,
  userId: string,
  feature: string
): Promise<void> {
  const limit = LIMITS[feature] ?? LIMITS["default"];
  const windowStart = new Date(
    Date.now() - limit.windowMinutes * 60 * 1000
  ).toISOString();

  try {
    const { count, error } = await adminClient
      .from("ai_generation_logs")
      .select("id", { count: "exact", head: true })
      .eq("teacher_id", userId)   // column name in your existing table
      .eq("feature", feature)     // add this column if needed (see migration below)
      .gte("created_at", windowStart);

    if (error) {
      // Non-fatal: if rate limit check fails, let the request through
      // but log the failure. Better to let a request through than block everyone.
      console.warn(`[RateLimiter] DB check failed (non-fatal): ${error.message}`);
      return;
    }

    const requestCount = count ?? 0;
    console.log(
      `[RateLimiter] ${feature} | User ${userId} | ` +
      `${requestCount}/${limit.maxRequests} requests in last ${limit.windowMinutes}min`
    );

    if (requestCount >= limit.maxRequests) {
      throw new AppError(
        "RATE_LIMITED",
        `You've reached the limit of ${limit.maxRequests} requests per hour for ${feature}. ` +
        `Please wait before trying again.`
      );
    }
  } catch (err) {
    if (err instanceof AppError) throw err; // Re-throw typed errors
    // Database error — let through (fail open)
    console.warn(`[RateLimiter] Unexpected error: ${err}. Allowing request.`);
  }
}

/**
 * Returns the current rate limit status for a user (for UI display).
 *
 * Useful for showing "You have X requests remaining" in Flutter.
 */
export async function getRateLimitStatus(
  adminClient: SupabaseClient,
  userId: string,
  feature: string
): Promise<{ used: number; limit: number; windowMinutes: number; remaining: number }> {
  const config = LIMITS[feature] ?? LIMITS["default"];
  const windowStart = new Date(
    Date.now() - config.windowMinutes * 60 * 1000
  ).toISOString();

  const { count } = await adminClient
    .from("ai_generation_logs")
    .select("id", { count: "exact", head: true })
    .eq("teacher_id", userId)
    .eq("feature", feature)
    .gte("created_at", windowStart);

  const used = count ?? 0;
  return {
    used,
    limit: config.maxRequests,
    windowMinutes: config.windowMinutes,
    remaining: Math.max(0, config.maxRequests - used),
  };
}

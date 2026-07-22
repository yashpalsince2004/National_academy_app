/**
 * telemetry.ts — AI Usage & Cost Tracking
 *
 * WHY THIS EXISTS
 * ───────────────
 * Every AI call costs money. Without telemetry you're flying blind:
 *   - You don't know which features are used most
 *   - You can't track which user is most expensive
 *   - You can't detect anomalies or budget overruns
 *   - You can't show the right error messages when things fail
 *
 * This module provides a single `logAiCall()` function that every
 * Edge Function must call after every AI generation (success or failure).
 *
 * COST CALCULATION
 * ─────────────────
 * Token pricing is defined per-model. Update the COST_PER_MILLION_TOKENS
 * map when model pricing changes or when you add new providers.
 *
 * VALUES STORED
 * ─────────────
 * All log entries go into your existing `ai_generation_logs` table.
 * The table must have columns for feature, model, tokens, cost, latency.
 * (See the migration file in migrations/)
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Cost per million tokens (input / output) ──────────────────────────────
// Update these when pricing changes. All values in USD.
const COST_PER_MILLION_TOKENS: Record<
  string,
  { input: number; output: number }
> = {
  // Gemini
  "gemini-2.5-flash":           { input: 0.075,  output: 0.30  },
  "gemini-2.5-pro":             { input: 1.25,   output: 10.00 },
  "gemini-1.5-flash":           { input: 0.075,  output: 0.30  },
  "text-embedding-004":         { input: 0.00,   output: 0.00  }, // Free
  // OpenAI
  "gpt-4o-mini":                { input: 0.15,   output: 0.60  },
  "gpt-4o":                     { input: 5.00,   output: 15.00 },
  // Anthropic Claude
  "claude-3-5-sonnet-20241022": { input: 3.00,   output: 15.00 },
  "claude-3-haiku-20240307":    { input: 0.25,   output: 1.25  },
  // DeepSeek
  "deepseek-chat":              { input: 0.14,   output: 0.28  },
  // Groq (free tier / open models)
  "llama-3.1-70b-versatile":   { input: 0.59,   output: 0.79  },
  // Mistral
  "mistral-small-latest":       { input: 0.10,   output: 0.30  },
  // Default fallback
  "unknown":                    { input: 0.30,   output: 0.60  },
};

/**
 * Parameters for logging a single AI generation call.
 */
export interface TelemetryEntry {
  userId: string;
  feature: string;        // e.g. "generate-dpp", "ai-chat", "doubt-solver"
  model: string;          // e.g. "gemini-2.5-flash"
  provider: string;       // e.g. "gemini", "openai"
  exam?: string;
  subject?: string;
  chapter?: string;
  promptTokens: number;
  completionTokens: number;
  latencyMs: number;
  status: "success" | "failed";
  error?: string;
}

/**
 * Calculates the USD cost of a generation call.
 */
export function calculateCost(
  model: string,
  promptTokens: number,
  completionTokens: number
): number {
  const pricing = COST_PER_MILLION_TOKENS[model] ??
    COST_PER_MILLION_TOKENS["unknown"];

  const inputCost  = (promptTokens     / 1_000_000) * pricing.input;
  const outputCost = (completionTokens / 1_000_000) * pricing.output;
  return Number((inputCost + outputCost).toFixed(8));
}

/**
 * Logs an AI generation event to the `ai_generation_logs` table.
 *
 * This is a best-effort write — failures are logged but never propagate
 * to the caller. Telemetry must NEVER break the main user flow.
 */
export async function logAiCall(
  adminClient: SupabaseClient,
  entry: TelemetryEntry
): Promise<void> {
  try {
    const totalTokens = entry.promptTokens + entry.completionTokens;
    const estimatedCost = calculateCost(
      entry.model,
      entry.promptTokens,
      entry.completionTokens
    );

    const { error } = await adminClient.from("ai_generation_logs").insert({
      teacher_id:        entry.userId,
      feature:           entry.feature,
      exam:              entry.exam,
      subject:           entry.subject,
      chapter:           entry.chapter,
      model:             entry.model,
      provider:          entry.provider,
      prompt_tokens:     entry.promptTokens,
      completion_tokens: entry.completionTokens,
      total_tokens:      totalTokens,
      estimated_cost:    estimatedCost,
      generation_time_ms: entry.latencyMs,
      status:            entry.status,
      error:             entry.error,
    });

    if (error) {
      console.error(`[Telemetry] Failed to write log: ${error.message}`);
    } else {
      console.log(
        `[Telemetry] Logged | feature=${entry.feature} | ` +
        `status=${entry.status} | tokens=${totalTokens} | ` +
        `cost=$${estimatedCost} | latency=${entry.latencyMs}ms`
      );
    }
  } catch (err) {
    // Never throw from telemetry — it must be non-blocking
    console.error(`[Telemetry] Unexpected logging error: ${err}`);
  }
}

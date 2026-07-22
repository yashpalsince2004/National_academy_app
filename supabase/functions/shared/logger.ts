/**
 * ═══════════════════════════════════════════════════════════════════════════
 * logger.ts — Centralized Structured Logger
 * Location: supabase/functions/shared/logger.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Every AI operation must be traceable. When something breaks at 2AM,
 * you need structured logs to diagnose the issue in minutes, not hours.
 *
 * This logger:
 * 1. Attaches a requestId to every log so you can trace one request across
 *    multiple log lines
 * 2. Structures logs as JSON so Supabase / any log aggregator can index them
 * 3. Includes timing, feature name, model, and user context automatically
 * 4. NEVER logs API keys, JWTs, or raw prompt content (security)
 *
 * WHY NOT console.log()?
 * ──────────────────────
 * console.log("Error:", err) produces unstructured text. You can't query it.
 * This logger produces: {"level":"error","requestId":"abc","feature":"dpp","error":"..."}
 * You can search by requestId, filter by level, or aggregate by feature.
 *
 * HOW SUPABASE LOGS WORK
 * ──────────────────────
 * Everything written to stdout/stderr in an Edge Function appears in:
 * Supabase Dashboard → Edge Functions → (your function) → Logs
 * These are retained for 1 hour on free tier, 7 days on pro.
 * ═══════════════════════════════════════════════════════════════════════════
 */

// ── Log levels ──────────────────────────────────────────────────────────────
export type LogLevel = "debug" | "info" | "warn" | "error";

// ── Log entry structure ─────────────────────────────────────────────────────
export interface LogEntry {
  level: LogLevel;
  requestId: string;
  timestamp: string;
  feature?: string;
  userId?: string;
  model?: string;
  provider?: string;
  message: string;
  latencyMs?: number;
  retryCount?: number;
  statusCode?: number;
  error?: string;
  metadata?: Record<string, unknown>;
}

// ── Logger class ────────────────────────────────────────────────────────────

export class Logger {
  private readonly requestId: string;
  private readonly feature: string;
  private userId?: string;
  private model?: string;
  private readonly startTime: number;

  constructor(feature: string, requestId?: string) {
    this.feature = feature;
    this.requestId = requestId ?? this.generateRequestId();
    this.startTime = Date.now();
  }

  /**
   * Sets user context. Call after JWT verification.
   */
  setUser(userId: string): this {
    this.userId = userId;
    return this;
  }

  /**
   * Sets the AI model being used. Call before AI invocation.
   */
  setModel(model: string): this {
    this.model = model;
    return this;
  }

  /**
   * Returns the requestId for inclusion in API responses (helps with support).
   */
  getRequestId(): string {
    return this.requestId;
  }

  /**
   * Returns elapsed time since logger was created.
   */
  getElapsedMs(): number {
    return Date.now() - this.startTime;
  }

  /**
   * DEBUG: Verbose tracing. Disable in production if log volume is too high.
   */
  debug(message: string, metadata?: Record<string, unknown>): void {
    this.write("debug", message, metadata);
  }

  /**
   * INFO: Normal operation events (request received, AI called, DB written).
   */
  info(message: string, metadata?: Record<string, unknown>): void {
    this.write("info", message, metadata);
  }

  /**
   * WARN: Recoverable issues (retry triggered, cache miss, validation quirk).
   */
  warn(message: string, metadata?: Record<string, unknown>): void {
    this.write("warn", message, metadata);
  }

  /**
   * ERROR: Failures that affect the user (AI failed, DB write failed, auth failed).
   * IMPORTANT: Never pass raw Error objects — extract the message first.
   * Never pass stack traces — they reveal internal implementation details.
   */
  error(message: string, error?: unknown, metadata?: Record<string, unknown>): void {
    const errorMsg = this.sanitiseError(error);
    this.write("error", message, { ...metadata, error: errorMsg });
  }

  /**
   * Logs AI generation completion with key metrics.
   * Call this after every AI call, success or failure.
   */
  aiComplete(params: {
    status: "success" | "failed";
    promptTokens: number;
    completionTokens: number;
    latencyMs: number;
    retryCount: number;
    provider: string;
  }): void {
    this.write("info", `AI generation ${params.status}`, {
      status: params.status,
      promptTokens: params.promptTokens,
      completionTokens: params.completionTokens,
      totalTokens: params.promptTokens + params.completionTokens,
      latencyMs: params.latencyMs,
      retryCount: params.retryCount,
      provider: params.provider,
    });
  }

  /**
   * Logs the incoming request (never logs sensitive fields like JWT).
   */
  requestStart(method: string, feature: string): void {
    this.info(`→ ${method} /${feature} received`, {
      elapsedMs: this.getElapsedMs(),
    });
  }

  /**
   * Logs the outgoing response.
   */
  requestEnd(statusCode: number): void {
    const elapsed = this.getElapsedMs();
    const level: LogLevel = statusCode >= 500 ? "error" : statusCode >= 400 ? "warn" : "info";
    this.write(level, `← Response ${statusCode} [${elapsed}ms]`, {
      statusCode,
      totalLatencyMs: elapsed,
    });
  }

  // ── Private methods ────────────────────────────────────────────────────

  private write(
    level: LogLevel,
    message: string,
    metadata?: Record<string, unknown>
  ): void {
    const entry: LogEntry = {
      level,
      requestId: this.requestId,
      timestamp: new Date().toISOString(),
      feature: this.feature,
      userId: this.userId,
      model: this.model,
      message,
      ...metadata,
    };

    // Remove undefined fields to keep logs clean
    const cleaned = Object.fromEntries(
      Object.entries(entry).filter(([, v]) => v !== undefined)
    );

    // All logs go to stdout as JSON — Supabase captures and displays them
    console.log(JSON.stringify(cleaned));
  }

  private generateRequestId(): string {
    // Compact ID: timestamp + random suffix
    // Example: "req_1721123456789_x7k2"
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).slice(2, 6);
    return `req_${timestamp}_${random}`;
  }

  /**
   * Extracts a safe, sanitised error message.
   * Never exposes stack traces or internal paths to logs (or clients).
   */
  private sanitiseError(error: unknown): string | undefined {
    if (!error) return undefined;
    if (typeof error === "string") return error;
    if (error instanceof Error) {
      // Only return the message, never the stack
      return error.message;
    }
    return String(error);
  }
}

/**
 * Factory function: creates a Logger for a given feature + optional requestId.
 * Import and use this in every Edge Function.
 *
 * Usage:
 *   const log = createLogger("generate-dpp");
 *   log.info("Starting DPP generation");
 *   log.error("AI failed", err);
 */
export function createLogger(feature: string, requestId?: string): Logger {
  return new Logger(feature, requestId);
}

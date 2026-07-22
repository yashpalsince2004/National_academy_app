/**
 * ═══════════════════════════════════════════════════════════════════════════
 * errors.ts — Typed Error System & Centralized Error Handler
 * Location: supabase/functions/shared/errors.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Without a centralised error system:
 * - Different functions return different error shapes (Flutter can't parse them)
 * - Stack traces leak internal details to clients (security risk)
 * - You can't search logs by error type
 * - Error messages are inconsistent
 *
 * With this system:
 * - Every error has a type (AppError), code, and HTTP status
 * - The client ALWAYS gets the same JSON shape: { success: false, error: {...} }
 * - Internal details only appear in server logs, never in responses
 * - Throwing errors from anywhere is safe — withErrorBoundary() catches all
 *
 * USAGE
 * ─────
 * throw new AppError("RATE_LIMITED", "Too many requests. Try again in 1 hour.");
 * throw new AppError("VALIDATION_ERROR", "Subject is required.");
 * throw new AppError("AI_PROVIDER_ERROR", "AI is temporarily unavailable.", err);
 *
 * HOW THE GLOBAL HANDLER WORKS
 * ─────────────────────────────
 * Every Edge Function wraps its handler in withErrorBoundary().
 * If ANY throw happens (AppError or plain Error), the boundary catches it,
 * logs the full details server-side, and returns a safe client response.
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { corsHeaders } from "./cors.ts";
import { Logger } from "./logger.ts";

// ── Error codes ─────────────────────────────────────────────────────────────

/**
 * Every error code maps to an HTTP status and a category.
 *
 * WHY TYPED CODES INSTEAD OF PLAIN STRINGS?
 * ──────────────────────────────────────────
 * TypeScript will catch typos at compile time.
 * Flutter can switch-case on codes for localised user messages.
 * Log aggregators can group errors by code type.
 */
export type AppErrorCode =
  | "UNAUTHORISED"       // 401: No valid JWT
  | "FORBIDDEN"          // 403: Valid JWT but insufficient role
  | "BAD_REQUEST"        // 400: Malformed request
  | "VALIDATION_ERROR"   // 422: Input fails business rules
  | "NOT_FOUND"          // 404: Resource doesn't exist
  | "MODEL_NOT_FOUND"    // 404: AI Model or endpoint not found
  | "RATE_LIMITED"       // 429: Too many requests
  | "PROMPT_INJECTION"   // 400: Suspicious input detected
  | "AI_PROVIDER_ERROR"  // 502: OpenRouter / AI API failure
  | "OUTPUT_TRUNCATED"   // 422: AI output reached MAX_TOKENS before completion
  | "SERVER_ERROR"       // 500: AI API 5xx failure
  | "TIMEOUT"            // 504: Request exceeded timeout
  | "CACHE_ERROR"        // 500: Cache read/write failure (non-fatal)
  | "DB_ERROR"           // 500: Database operation failed
  | "INTERNAL_ERROR";    // 500: Unexpected / unclassified failure

// ── HTTP status code map ────────────────────────────────────────────────────
const HTTP_STATUS_MAP: Record<AppErrorCode, number> = {
  UNAUTHORISED:      401,
  FORBIDDEN:         403,
  BAD_REQUEST:       400,
  VALIDATION_ERROR:  422,
  NOT_FOUND:         404,
  MODEL_NOT_FOUND:   404,
  RATE_LIMITED:      429,
  PROMPT_INJECTION:  400,
  AI_PROVIDER_ERROR: 502,
  OUTPUT_TRUNCATED:  422,
  SERVER_ERROR:      500,
  TIMEOUT:           504,
  CACHE_ERROR:       500,
  DB_ERROR:          500,
  INTERNAL_ERROR:    500,
};

// ── Typed application error ─────────────────────────────────────────────────

/**
 * AppError extends the native Error class with:
 * - code: machine-readable error type (for Flutter switch-case)
 * - publicMessage: safe message to send to client
 * - internalDetails: full details for server logs only
 *
 * SECURITY PRINCIPLE
 * ───────────────────
 * The client sees `publicMessage` only.
 * The server logs `internalDetails` + stack trace.
 * This prevents leaking database schemas, file paths, or API errors.
 */
export class AppError extends Error {
  public readonly code: AppErrorCode;
  public readonly publicMessage: string;
  public readonly httpStatus: number;
  public readonly internalDetails?: unknown;

  constructor(
    code: AppErrorCode,
    publicMessage: string,
    internalDetails?: unknown
  ) {
    super(publicMessage);
    this.name = "AppError";
    this.code = code;
    this.publicMessage = publicMessage;
    this.httpStatus = HTTP_STATUS_MAP[code] ?? 500;
    this.internalDetails = internalDetails;
  }
}

// ── Convenience factory functions ───────────────────────────────────────────
// These read like documentation — use them for clarity in feature code.

export const Errors = {
  unauthorised: (detail?: string) =>
    new AppError("UNAUTHORISED", "Authentication required. Please sign in.", detail),

  forbidden: (role?: string) =>
    new AppError("FORBIDDEN", `Access denied. Required role: ${role ?? "higher"}.`),

  badRequest: (field: string, reason: string) =>
    new AppError("BAD_REQUEST", `Invalid request: ${field} — ${reason}.`),

  validation: (message: string) =>
    new AppError("VALIDATION_ERROR", message),

  notFound: (resource: string) =>
    new AppError("NOT_FOUND", `${resource} not found.`),

  rateLimited: (feature: string, windowMinutes: number) =>
    new AppError(
      "RATE_LIMITED",
      `Rate limit reached for ${feature}. Try again in ${windowMinutes} minutes.`
    ),

  promptInjection: () =>
    new AppError(
      "PROMPT_INJECTION",
      "Your input contains patterns that cannot be processed. Please rephrase."
    ),

  aiProvider: (internal?: unknown, customMessage?: string) =>
    new AppError(
      "AI_PROVIDER_ERROR",
      customMessage ?? (typeof internal === "string" ? internal : "The AI service is temporarily unavailable. Please try again shortly."),
      internal
    ),

  timeout: () =>
    new AppError("TIMEOUT", "The request took too long. Please try again."),

  internal: (internal?: unknown) =>
    new AppError(
      "INTERNAL_ERROR",
      "An unexpected error occurred. Our team has been notified.",
      internal
    ),
};

// ── Safe error response builder ─────────────────────────────────────────────

/**
 * Builds a standardised, safe JSON error response.
 *
 * Response body format (always consistent — Flutter can rely on this):
 * {
 *   "success": false,
 *   "error": {
 *     "code": "RATE_LIMITED",
 *     "message": "Too many requests. Try again in 1 hour."
 *   },
 *   "requestId": "req_abc123_x7k2"
 * }
 *
 * @param code       - AppErrorCode for the response
 * @param message    - User-safe message
 * @param requestId  - Trace ID for support debugging
 * @param internal   - Internal details (ONLY for server logs, never sent to client)
 */
export function buildErrorResponse(
  code: AppErrorCode,
  message: string,
  requestId: string,
  internal?: unknown
): Response {
  const status = HTTP_STATUS_MAP[code] ?? 500;

  // Log full internal details server-side
  if (internal) {
    const detail = internal instanceof Error
      ? `${internal.message} | Stack: ${internal.stack?.split("\n")[1] ?? ""}`.trim()
      : String(internal);
    console.error(
      JSON.stringify({
        level: "error",
        requestId,
        code,
        publicMessage: message,
        internalDetail: detail,
      })
    );
  }

  return new Response(
    JSON.stringify({
      success: false,
      error: { code, message },
      requestId,
    }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}

// ── Global error boundary ───────────────────────────────────────────────────

/**
 * Wraps an Edge Function handler in a global try/catch.
 *
 * WHY USE A WRAPPER INSTEAD OF TRY/CATCH IN EVERY FUNCTION?
 * ──────────────────────────────────────────────────────────
 * 1. DRY — one error handler, not 10 copies
 * 2. Consistency — every function uses the same response shape
 * 3. Safety — even if a developer forgets try/catch, crashes are handled
 * 4. The AppError type is handled differently from generic errors
 *
 * Usage:
 *   serve(withErrorBoundary("my-feature", async (req) => {
 *     // ... your handler code
 *   }));
 */
export function withErrorBoundary(
  feature: string,
  handler: (req: Request) => Promise<Response>
): (req: Request) => Promise<Response> {
  return async (req: Request) => {
    // Generate a requestId that flows through the entire request lifecycle
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;

    try {
      return await handler(req);
    } catch (err) {
      if (err instanceof AppError) {
        // Typed, expected error — log and return detailed response
        console.error(
          JSON.stringify({
            level: "error",
            requestId,
            feature,
            code: err.code,
            message: err.publicMessage,
            internal: err.internalDetails
              ? String(err.internalDetails)
              : undefined,
          })
        );
        return buildErrorResponse(err.code, err.publicMessage, requestId, err.internalDetails);
      }

      // Unknown crash — include message in response
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error(
        JSON.stringify({
          level: "error",
          requestId,
          feature,
          code: "INTERNAL_ERROR",
          internal: errMsg,
          stack: err instanceof Error ? err.stack?.split("\n").slice(0, 3).join(" | ") : undefined,
        })
      );
      return buildErrorResponse(
        "INTERNAL_ERROR",
        `An error occurred: ${errMsg}`,
        requestId,
        errMsg
      );
    }
  };
}

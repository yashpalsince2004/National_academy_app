/**
 * error_handler.ts — Centralised error classification and response builder
 *
 * WHY THIS EXISTS
 * ───────────────
 * Without this, every function would have ad-hoc error handling with different
 * response shapes, leaking stack traces, and inconsistent HTTP status codes.
 * This module provides one canonical place to:
 *   1. Map known error types to HTTP status codes
 *   2. Log detailed diagnostics server-side (visible in Supabase logs)
 *   3. Return a SAFE, sanitised response to the client (never expose internals)
 *
 * SECURITY NOTE
 * ─────────────
 * The client NEVER receives a raw stack trace or internal error message.
 * Only a human-readable "public" message is sent. Full details go to logs.
 */

import { corsHeaders } from "./cors.ts";

// ── Public-facing error codes ─────────────────────────────────────────────
export type AppErrorCode =
  | "UNAUTHORISED"
  | "FORBIDDEN"
  | "BAD_REQUEST"
  | "NOT_FOUND"
  | "RATE_LIMITED"
  | "AI_PROVIDER_ERROR"
  | "VALIDATION_ERROR"
  | "TIMEOUT"
  | "INTERNAL_ERROR";

// ── Mapping from code → HTTP status ──────────────────────────────────────
const STATUS_MAP: Record<AppErrorCode, number> = {
  UNAUTHORISED: 401,
  FORBIDDEN: 403,
  BAD_REQUEST: 400,
  NOT_FOUND: 404,
  RATE_LIMITED: 429,
  AI_PROVIDER_ERROR: 502,
  VALIDATION_ERROR: 422,
  TIMEOUT: 504,
  INTERNAL_ERROR: 500,
};

/**
 * Typed application error.
 * Throw this anywhere in your Edge Function — the global handler catches it.
 */
export class AppError extends Error {
  public readonly code: AppErrorCode;
  public readonly publicMessage: string;
  public readonly details?: unknown;

  constructor(
    code: AppErrorCode,
    publicMessage: string,
    internalDetails?: unknown
  ) {
    super(publicMessage);
    this.name = "AppError";
    this.code = code;
    this.publicMessage = publicMessage;
    this.details = internalDetails;
  }
}

/**
 * Builds a standardised, safe JSON error response.
 *
 * @param code    - One of the AppErrorCode values
 * @param message - Human-readable message sent to the client
 * @param internal - Internal detail for server logs only (never sent to client)
 */
export function errorResponse(
  code: AppErrorCode,
  message: string,
  internal?: unknown
): Response {
  const status = STATUS_MAP[code] ?? 500;

  // Log full details on the server (visible in Supabase → Edge Functions → Logs)
  if (internal) {
    const detail = internal instanceof Error ? internal.stack : String(internal);
    console.error(`[ErrorHandler] ${code} — ${message} | Internal: ${detail}`);
  } else {
    console.error(`[ErrorHandler] ${code} — ${message}`);
  }

  return new Response(
    JSON.stringify({
      success: false,
      error: {
        code,
        message,
      },
    }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}

/**
 * Wraps the main handler in a global try/catch.
 * Catches both AppError (typed) and generic Errors safely.
 *
 * Usage:
 *   serve(withErrorHandler(async (req) => { ... }));
 */
export function withErrorHandler(
  handler: (req: Request) => Promise<Response>
): (req: Request) => Promise<Response> {
  return async (req: Request) => {
    try {
      return await handler(req);
    } catch (err) {
      if (err instanceof AppError) {
        return errorResponse(err.code, err.publicMessage, err.details);
      }
      // Unknown/unexpected crash — return generic 500, log full error
      const msg = err instanceof Error ? err.message : String(err);
      console.error("[GlobalCrash] Unhandled exception:", err);
      return errorResponse(
        "INTERNAL_ERROR",
        "An unexpected error occurred. Please try again.",
        msg
      );
    }
  };
}

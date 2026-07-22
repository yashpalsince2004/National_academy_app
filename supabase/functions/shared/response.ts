/**
 * ═══════════════════════════════════════════════════════════════════════════
 * response.ts — Standard Response Builder
 * Location: supabase/functions/shared/response.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Ensures every Edge Function returns EXACTLY the same response shape.
 * Flutter's data layer can rely on this contract without defensive coding.
 *
 * SUCCESS SHAPE:
 * {
 *   "success": true,
 *   "data": { ... },          ← the actual payload
 *   "requestId": "req_..."    ← for support tracing
 * }
 *
 * ERROR SHAPE (from errors.ts):
 * {
 *   "success": false,
 *   "error": { "code": "...", "message": "..." },
 *   "requestId": "req_..."
 * }
 *
 * WHY WRAP IN { data: ... }?
 * ──────────────────────────
 * Consistency. If you return the payload directly, every feature has
 * a different root shape. With wrapping, Flutter always does:
 *   final data = response['data'];
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { corsHeaders } from "./cors.ts";

/**
 * Builds a standard JSON success response.
 *
 * @param data      - The payload to send to Flutter
 * @param requestId - The trace ID from the Logger
 * @param status    - HTTP status (default 200)
 */
export function successResponse(
  data: unknown,
  requestId: string,
  status = 200
): Response {
  return new Response(
    JSON.stringify({
      success: true,
      data,
      requestId,
    }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}

/**
 * Builds a paginated list response.
 *
 * @param items     - Array of items
 * @param total     - Total count (for pagination)
 * @param page      - Current page number
 * @param requestId - Trace ID
 */
export function listResponse(
  items: unknown[],
  total: number,
  page: number,
  requestId: string
): Response {
  return new Response(
    JSON.stringify({
      success: true,
      data: {
        items,
        total,
        page,
        count: items.length,
      },
      requestId,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
}

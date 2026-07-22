/**
 * ═══════════════════════════════════════════════════════════════════════════
 * cors.ts — CORS Configuration & Response Utilities
 * Location: supabase/functions/shared/cors.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Browsers enforce CORS (Cross-Origin Resource Sharing) for security.
 * Flutter apps on mobile don't enforce browser CORS, but:
 * 1. Flutter Web does enforce it
 * 2. Supabase's own client SDK sends preflight OPTIONS requests
 * 3. Local development tools (Swagger, Postman Web) enforce it
 *
 * Every Edge Function that receives requests from a browser or Flutter Web
 * MUST respond correctly to OPTIONS preflight requests.
 *
 * HOW CORS PREFLIGHT WORKS
 * ─────────────────────────
 * 1. Browser sends: OPTIONS /functions/v1/ai-chat
 * 2. Server responds: "Yes, this origin is allowed. These headers are OK."
 * 3. Browser sends the actual POST request
 * Without step 2, the browser blocks step 3 completely.
 *
 * WHY "*" FOR ALLOW-ORIGIN?
 * ──────────────────────────
 * For authenticated APIs (JWT required), "*" is safe because:
 * - The JWT is the real security layer
 * - Without a valid JWT, the request is rejected regardless of origin
 * - Restricting origins would break Flutter Web on different domains
 *
 * For truly public unauthenticated APIs, you'd lock this down to your domain.
 * ═══════════════════════════════════════════════════════════════════════════
 */

/**
 * Standard CORS headers for all Edge Function responses.
 *
 * Access-Control-Allow-Origin: "*"
 *   → Accept requests from any domain (safe for JWT-protected APIs)
 *
 * Access-Control-Allow-Headers: "..."
 *   → Tell browsers these headers are allowed in requests
 *   → "authorization" is needed for the JWT Bearer token
 *   → "x-client-info" is sent by the Supabase JS SDK automatically
 *   → "apikey" is the Supabase anon key (public, not a secret)
 *   → "content-type" is needed for JSON request bodies
 *   → "x-request-id" is our custom tracing header
 *
 * Access-Control-Allow-Methods: "..."
 *   → Only POST and OPTIONS. GET would allow caching by browsers/CDNs,
 *     which we don't want for AI-generated content.
 *
 * Access-Control-Max-Age: "86400"
 *   → Cache the preflight response for 24 hours.
 *     Without this, EVERY request would trigger a preflight OPTIONS call.
 *     This halves the number of HTTP requests from the client.
 */
export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-request-id",
  "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
  "Access-Control-Max-Age": "86400",
};

/**
 * Handles CORS preflight (OPTIONS) requests.
 *
 * MUST be called first in every Edge Function handler.
 * If the request is an OPTIONS preflight, return immediately.
 * If not, return null and continue processing.
 *
 * Usage:
 *   const preflight = handleCors(req);
 *   if (preflight) return preflight;
 */
export function handleCors(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }
  return null;
}

/**
 * Wraps any data into a standard JSON success response.
 *
 * All responses include:
 * - CORS headers (required for browser/Flutter Web)
 * - Content-Type: application/json
 * - The data payload as JSON
 *
 * Usage:
 *   return jsonOk({ success: true, dppId: "abc" });
 *   return jsonOk({ success: true, reply: "..." }, 201);
 */
export function jsonOk(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Alias for jsonOk to support jsonResponse function calls.
 */
export const jsonResponse = jsonOk;


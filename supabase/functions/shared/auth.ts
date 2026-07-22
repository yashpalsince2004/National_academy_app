/**
 * ═══════════════════════════════════════════════════════════════════════════
 * auth.ts — JWT Verification, User Identity & Role-Based Access Control
 * Location: supabase/functions/shared/auth.ts
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * PURPOSE
 * ────────
 * Every AI call costs money and must be made by a verified, authorised user.
 * This module is the security gate for every Edge Function.
 *
 * ────────────────────────────────────────────────────────────────────────────
 * HOW SUPABASE SECRETS WORK (and why Flutter cannot access them)
 * ────────────────────────────────────────────────────────────────────────────
 *
 * Supabase Secrets are encrypted environment variables stored in Supabase Vault.
 * They are ONLY accessible to server-side code running inside Edge Functions.
 *
 *   Flutter App
 *       │  "I want to call ai-chat"
 *       │  POST /functions/v1/ai-chat
 *       │  Authorization: Bearer eyJhbG...  (Supabase JWT)
 *       │
 *       ▼
 *   Supabase Edge Function Runtime (server-side, in Deno)
 *       │
 *       │  Deno.env.get("OPENROUTER_API_KEY") → "sk-or-v1-..."
 *       │  [Flutter CANNOT run this. This code runs on Supabase's servers.]
 *       │
 *       └─ Calls OpenRouter with the API key
 *
 * Flutter sends a REQUEST to the Edge Function URL.
 * Flutter never executes the Edge Function code.
 * Flutter never sees Deno.env — that's server-only.
 * This is exactly like a traditional backend API.
 *
 * ────────────────────────────────────────────────────────────────────────────
 * HOW JWT VERIFICATION WORKS
 * ────────────────────────────────────────────────────────────────────────────
 *
 * When a user logs in with Supabase Auth, Supabase issues a JWT signed with
 * its private key. Flutter stores this JWT and sends it in every API request.
 *
 * In this Edge Function:
 * 1. We extract the JWT from the Authorization header
 * 2. We create a Supabase client WITH the user's JWT
 * 3. We call auth.getUser() — Supabase verifies the JWT signature internally
 *    using its public key (no external network call needed)
 * 4. If verification passes, we get back the user object
 *
 * CAN FLUTTER FAKE A JWT?
 * ────────────────────────
 * No. The JWT is signed with Supabase's PRIVATE key (which only Supabase knows).
 * Flutter only ever receives the SIGNED token — it cannot create or modify JWTs
 * without the private key.
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Errors, AppError } from "./errors.ts";

// ── Role types aligned with your profiles table ─────────────────────────────
export type UserRole = "super_admin" | "admin" | "teacher" | "student" | "unknown";

// ── User tier for rate limiting ──────────────────────────────────────────────
export type UserTier = "admin" | "teacher" | "student" | "free" | "guest";

// ── Authenticated user context returned by requireAuth() ──────────────────
export interface AuthContext {
  /** Supabase user UUID */
  id: string;

  /** User email (may be undefined for some OAuth providers) */
  email: string | undefined;

  /** Role from your profiles table */
  role: UserRole;

  /** Tier used for rate limiting */
  tier: UserTier;

  /** User-scoped Supabase client — all queries respect Row Level Security */
  userClient: SupabaseClient;

  /**
   * Admin/service-role Supabase client — BYPASSES Row Level Security.
   * Use ONLY for server-side operations where the service needs elevated access.
   * Example: saving generated DPPs that belong to the user, not the service.
   * NEVER pass this to untrusted code or expose it to the client.
   */
  adminClient: SupabaseClient;
}

/**
 * Resolves the authenticated user from the incoming request.
 *
 * Steps:
 * 1. Extracts Bearer token from Authorization header
 * 2. Creates a user-scoped Supabase client
 * 3. Verifies JWT via auth.getUser()
 * 4. Queries the profiles table for the user's role
 * 5. Optionally enforces RBAC (role-based access control)
 *
 * @param req           - The incoming HTTP request
 * @param requiredRoles - If set, only these roles may proceed
 *
 * @throws AppError("UNAUTHORISED")  if JWT is missing or invalid
 * @throws AppError("FORBIDDEN")     if role is not in requiredRoles
 */
export async function requireAuth(
  req: Request,
  requiredRoles: UserRole[] = []
): Promise<AuthContext> {
  // ── Step 1: Extract Authorization header ─────────────────────────────────
  const authHeader = req.headers.get("Authorization");

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    throw Errors.unauthorised(
      "Authorization header missing or malformed. Expected: 'Bearer <jwt>'"
    );
  }

  // ── Step 2: Read Supabase environment variables ───────────────────────────
  // These are Supabase Secrets — only available server-side in Edge Functions.
  // Flutter cannot access Deno.env — this runs on Supabase's infrastructure.
  const supabaseUrl     = Deno.env.get("SUPABASE_URL");
  const supabaseAnon    = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseService = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseAnon || !supabaseService) {
    // This should never happen in production — it indicates server misconfiguration
    throw new AppError(
      "INTERNAL_ERROR",
      "Server configuration error. Contact support.",
      "Missing SUPABASE_URL, SUPABASE_ANON_KEY, or SUPABASE_SERVICE_ROLE_KEY"
    );
  }

  // ── Step 3: Create user-scoped client and verify JWT ─────────────────────
  // This client uses the user's JWT. All Supabase queries through this client
  // are subject to Row Level Security policies — users can only access their data.
  const userClient = createClient(supabaseUrl, supabaseAnon, {
    global: { headers: { Authorization: authHeader } },
    auth:   { persistSession: false },
  });

  const { data: { user }, error: authError } = await userClient.auth.getUser();

  if (authError || !user) {
    throw Errors.unauthorised(
      authError?.message ?? "JWT verification failed — token expired or invalid"
    );
  }

  // ── Step 4: Create admin client (bypasses RLS) ────────────────────────────
  // Used for server-side writes (AI logs, generated content) where the service
  // role needs to write data that belongs to the user.
  // IMPORTANT: Never expose this client to Flutter or use it for user-facing reads.
  const adminClient = createClient(supabaseUrl, supabaseService, {
    auth: { persistSession: false },
  });

  // ── Step 5: Resolve user role from profiles table ─────────────────────────
  let role: UserRole = "unknown";
  try {
    const { data: profile } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profile?.role) {
      role = profile.role as UserRole;
    }
  } catch {
    // Role resolution failure is non-fatal — user proceeds with 'unknown' role.
    // The RBAC check below will still enforce restrictions.
    console.warn(
      JSON.stringify({
        level: "warn",
        message: "Role resolution failed — user proceeds as unknown",
        userId: user.id,
      })
    );
  }

  // ── Step 6: Enforce RBAC ──────────────────────────────────────────────────
  if (requiredRoles.length > 0 && !requiredRoles.includes(role)) {
    throw Errors.forbidden(requiredRoles.join(", "));
  }

  // ── Step 7: Determine rate limit tier ────────────────────────────────────
  const tier = resolveUserTier(role);

  console.log(
    JSON.stringify({
      level: "info",
      message: "Auth verified",
      userId: user.id,
      role,
      tier,
    })
  );

  return { id: user.id, email: user.email, role, tier, userClient, adminClient };
}

/**
 * Maps user role to a rate limiting tier.
 *
 * WHY SEPARATE ROLE FROM TIER?
 * ──────────────────────────────
 * Roles are about permissions (what can you DO?).
 * Tiers are about limits (how MUCH can you do?).
 * Keeping them separate lets you adjust rate limits independently.
 */
function resolveUserTier(role: UserRole): UserTier {
  switch (role) {
    case "super_admin":
    case "admin":
      return "admin";
    case "teacher":
      return "teacher";
    case "student":
      return "student";
    default:
      return "free";
  }
}

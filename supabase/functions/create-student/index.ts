// Supabase Edge Function: create-student
// Runs server-side using the Service Role Key.
// The Flutter client calls this via supabase.functions.invoke('create-student').
// This avoids the PKCE _asyncStorage error that occurs when calling
// supabase.auth.signUp() directly from a Flutter client session.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Verify the calling user is an authenticated admin ────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Admin client (anon key) — used to verify the caller's session
    const callerClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const {
      data: { user: callerUser },
      error: callerError,
    } = await callerClient.auth.getUser();

    if (callerError || !callerUser) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Optionally verify caller is an admin (check role column in profiles)
    const { data: callerProfile } = await callerClient
      .from("profiles")
      .select("role")
      .eq("id", callerUser.id)
      .single();

    if (!callerProfile || !['admin', 'super_admin'].includes(callerProfile.role)) {
      return new Response(JSON.stringify({ error: "Forbidden: Admin access required" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── 2. Parse request body ───────────────────────────────────────────────
    const { registrationData, password } = await req.json();
    const personal = registrationData.personal ?? {};
    const academic = registrationData.academic ?? {};
    
    // Generate temporary password in format NA@8245
    const tempPassword = `NA@${Math.floor(1000 + Math.random() * 9000)}`;
    const finalPassword = password || tempPassword;

    const parents = registrationData.parents ?? {};

    const email = (personal.email ?? "").trim().toLowerCase();
    const phone = (personal.phone ?? "").trim();

    // Build full name
    const parts = [personal.firstName, personal.middleName, personal.lastName]
      .filter(Boolean)
      .join(" ")
      .replace(/\s+/g, " ")
      .trim();
    const fullName = parts || "Student";

    // If no email was provided, generate a placeholder using the phone
    const effectiveEmail =
      email.length > 0
        ? email
        : `${phone.replace(/\D/g, "")}@nationalacademy.internal`;

    // ── 3. Create Auth user using the Service Role Key ─────────────────────
    // The service role key bypasses PKCE entirely — no asyncStorage needed.
    const adminClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    const { data: authData, error: authError } =
      await adminClient.auth.admin.createUser({
        email: effectiveEmail,
        password: finalPassword,
        email_confirm: true, // Skip email confirmation for admin-created accounts
        user_metadata: {
          full_name: fullName,
          role: "student",
        },
      });

    if (authError || !authData?.user) {
      return new Response(
        JSON.stringify({ error: `Auth user creation failed: ${authError?.message}` }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const uid = authData.user.id;

    // ── 4. Update profiles table (auto-created by DB trigger) ──────────────
    await adminClient.from("profiles").update({
      full_name: fullName,
      phone: phone,
      role: "student",
      email: effectiveEmail,
    }).eq("id", uid);

    // ── 5. Build the address string ─────────────────────────────────────────
    const addressParts = [
      personal.address,
      personal.city,
      personal.state,
      personal.pinCode ? `- ${personal.pinCode}` : null,
    ].filter(Boolean);
    const addressStr = addressParts.join(", ");

    // ── 6. Insert into students table ───────────────────────────────────────
    const father = parents.father ?? {};
    const mother = parents.mother ?? {};

    const studentData = {
      profile_id: uid,
      dob: personal.dob ?? null,
      address: addressStr,
      school_name: academic.previousSchoolName ?? "",
      guardian_name: father.name ?? "",
      guardian_phone: father.mobile ?? "",
      guardian_relation: "Father",
      photo_url: personal.photoUrl ?? "",
      marksheet_url: academic.marksheetUrl ?? "",
      id_proof_url: "",
      previous_school: academic.previousSchoolName ?? "",
      previous_class: academic.classLevel ?? "",
      previous_percentage: academic.previousPercentage ?? "",
      status: "active",
      password_changed: false,
      additional_info: {
        first_name: personal.firstName ?? "",
        middle_name: personal.middleName ?? "",
        last_name: personal.lastName ?? "",
        gender: personal.gender ?? "",
        blood_group: personal.bloodGroup ?? null,
        aadhaar_number: personal.aadhaarNumber ?? null,
        target_exams: academic.targetExams ?? [],
        academic_class: academic.classLevel ?? "",
        academic_board: academic.board ?? "",
        academic_passing_year: academic.passingYear ?? null,
        academic_score_percentage: academic.previousPercentage ?? null,
        father_details: {
          name: father.name ?? "",
          mobile: father.mobile ?? "",
          email: father.email ?? "",
          occupation: father.occupation ?? "",
        },
        mother_details: {
          name: mother.name ?? "",
          mobile: mother.mobile ?? "",
          email: mother.email ?? "",
          occupation: mother.occupation ?? "",
        },
      },
    };

    const { data: insertedStudent, error: insertError } = await adminClient
      .from("students")
      .insert(studentData)
      .select("roll_no, created_at")
      .single();

    if (insertError) {
      // Roll back: delete the auth user if student insert failed
      await adminClient.auth.admin.deleteUser(uid);
      return new Response(
        JSON.stringify({ error: `Student record creation failed: ${insertError.message}` }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ── 7. Return success payload ───────────────────────────────────────────
    return new Response(
      JSON.stringify({
        success: true,
        studentId: uid,
        rollNumber: insertedStudent.roll_no ?? "TBD",
        temporaryPassword: finalPassword,
        registrationDate: insertedStudent.created_at ?? new Date().toISOString(),
        admissionNumber: insertedStudent.roll_no ?? "TBD",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Verify caller has admin/super_admin privileges
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const callerClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user: callerUser }, error: callerError } = await callerClient.auth.getUser();

    if (callerError || !callerUser) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: callerProfile } = await callerClient
      .from("profiles")
      .select("role")
      .eq("id", callerUser.id)
      .single();

    if (!callerProfile || !['admin', 'super_admin'].includes(callerProfile.role)) {
      return new Response(JSON.stringify({ error: "Forbidden: Admin privileges required" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Parse request payload
    const { email, password, fullName, phone, username, subject } = await req.json();

    if (!email || !password || !fullName || !username) {
      return new Response(JSON.stringify({ error: "Missing required fields: email, password, fullName, username" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Normalize username (starts with @)
    let cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.startsWith('@')) {
      cleanUsername = cleanUsername.slice(1);
    }
    const loginEmail = `${cleanUsername}@nationalacademy.internal`;

    const adminClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { persistSession: false } }
    );

    // 3. Create auth user with teacher role metadata
    const { data: authData, error: authError } = await adminClient.auth.admin.createUser({
      email: loginEmail,
      password: password,
      email_confirm: true,
      user_metadata: {
        full_name: fullName.trim(),
        role: "teacher",
        contact_email: email.trim().toLowerCase(),
        username: username.trim(),
        subject: subject?.trim() || "General",
      },
    });

    if (authError || !authData?.user) {
      return new Response(JSON.stringify({ error: `Auth creation failed: ${authError?.message}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const uid = authData.user.id;

    // 4. Update the profiles table
    const { error: profileError } = await adminClient
      .from("profiles")
      .update({
        phone: phone ? phone.trim() : null,
        full_name: fullName.trim(),
        role: "teacher",
        subject: subject?.trim() || "General",
      })
      .eq("id", uid);

    if (profileError) {
      await adminClient.auth.admin.deleteUser(uid);
      return new Response(JSON.stringify({ error: `Profile setup failed: ${profileError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, teacherId: uid }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

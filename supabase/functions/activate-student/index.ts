import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { roll_number, email, password } = await req.json()

    if (!roll_number || !email || !password) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: roll_number, email, password" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ""
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ""

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    const emailTrimmed = email.trim().toLowerCase()

    // 1. Verify student exists in pre-seeded students table
    const { data: student, error: studentError } = await supabase
      .from('students')
      .select('id, auth_user_id, status')
      .eq('na_roll_number', roll_number.trim())
      .eq('email', emailTrimmed)
      .maybeSingle()

    if (studentError || !student) {
      return new Response(
        JSON.stringify({ error: "Invalid roll number or unregistered email. Please contact Admin." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // 2. Verify account status
    if (student.status !== 'Active') {
      return new Response(
        JSON.stringify({ error: "Your student enrollment is currently suspended or completed." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // 3. Verify account isn't already activated
    if (student.auth_user_id) {
      return new Response(
        JSON.stringify({ error: "Account is already activated. Please sign in directly." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // 4. Create user in Supabase Auth via Admin Client
    const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
      email: emailTrimmed,
      password: password,
      email_confirm: true
    })

    if (authError || !authUser.user) {
      return new Response(
        JSON.stringify({ error: authError?.message ?? "Failed to provision authentication account." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    // 5. Update students table to link auth_user_id
    const { error: updateError } = await supabase
      .from('students')
      .update({ auth_user_id: authUser.user.id })
      .eq('id', student.id)

    if (updateError) {
      await supabase.auth.admin.deleteUser(authUser.user.id)
      return new Response(
        JSON.stringify({ error: "Failed to link profile database record. Try again." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    return new Response(
      JSON.stringify({ success: true, message: "Account activated successfully. You can now log in." }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})

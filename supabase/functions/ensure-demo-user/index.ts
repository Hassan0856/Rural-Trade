// @ts-nocheck
// supabase/functions/ensure-demo-user/index.ts
//
// Purpose: make phone-number demo login work every time, regardless of
// the project's "Confirm email" setting. Client-side signUp() always
// respects that setting; this function uses the service-role admin API
// to create the account with email_confirm forced true, which bypasses
// the confirmation requirement at creation time. No dashboard toggle to
// remember, and it can't drift out of sync again.
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically
// into every Edge Function's environment — nothing to configure.
//
// Deploy: npx supabase functions deploy ensure-demo-user
// (see the deployment steps in chat for the one-time CLI login/link)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DEMO_OTP = "123456";

Deno.serve(async (req: Request) => {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const { phone, otp } = await req.json();

    if (otp !== DEMO_OTP) {
      return new Response(JSON.stringify({ error: "Incorrect code." }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const digits = String(phone ?? "").replace(/\D/g, "");
    if (digits.length < 12) {
      return new Response(JSON.stringify({ error: "Invalid phone number." }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const email = `${digits}@village-exchange.app`;
    const password = `vx_${digits}_demo`;

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Idempotent. email_confirm: true creates the account already confirmed,
    // so the client's later signInWithPassword() always succeeds — the
    // "Confirm email" toggle never gets a chance to block it.
    const { error } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { phone: `+${digits}` },
    });

    if (error && !error.message.toLowerCase().includes("already been registered")) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
// @ts-nocheck
// supabase/functions/gemini-generate/index.ts
//
// Generic Gemini text-generation proxy. Client sends { prompt: string },
// gets back { text: string }.
//
// Why this exists: generativelanguage.googleapis.com does not return
// CORS headers for direct browser requests, so Flutter Web's fetch is
// blocked client-side even with a valid, unrestricted API key. This is a
// current, widely-reported Google API limitation — not a bug in this
// app, and not fixable from the client side. Routing through an Edge
// Function (which DOES set CORS headers, same as ensure-demo-user
// already does) fixes it, and also keeps the API key server-side only.
//
// Used by: ai_service.dart (match explanation, trust summary) and
// weather_service.dart (forecast alert sentence) — all three should call
// this instead of generativelanguage.googleapis.com directly.
//
// Deploy: npx supabase functions deploy gemini-generate
// Secret:  npx supabase secrets set GEMINI_API_KEY=your_real_key_here
// (GEMINI_API_KEY is NOT auto-injected like SUPABASE_URL — set it
// explicitly, once.)

const MODEL = "gemini-3.5-flash"; // current GA Flash model as of mid-2026;
// gemini-2.0-flash and earlier have been shut down — using an old model
// name here will fail with a 404 regardless of everything else working.

Deno.serve(async (req: Request) => {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const { prompt } = await req.json();
    if (!prompt || typeof prompt !== "string") {
      return new Response(JSON.stringify({ error: "Missing prompt." }), {
        status: 400,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY secret not set." }),
        { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
      );
    }

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": apiKey,
        },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      },
    );

    if (!geminiRes.ok) {
      const errBody = await geminiRes.text();
      return new Response(JSON.stringify({ error: errBody }), {
        status: geminiRes.status,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const data = await geminiRes.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    return new Response(JSON.stringify({ text }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
// supabase/functions/gemini-generate/index.ts
//
// Generic text-generation proxy. Client sends { prompt: string }, gets
// back { text: string }.
//
// Why this exists: generativelanguage.googleapis.com does not return
// CORS headers for direct browser requests, so Flutter Web's fetch is
// blocked client-side even with a valid, unrestricted API key. Routing
// through an Edge Function (which DOES set CORS headers, same as
// ensure-demo-user) fixes it, and also keeps API keys server-side only.
//
// GROQ FALLBACK: Gemini's free tier caps out at 20 requests/DAY total
// (confirmed via a live 429 RESOURCE_EXHAUSTED response) — easy to blow
// through during testing, let alone a live demo with retries. When
// Gemini returns 429, this now falls back to Groq's free tier
// (openai/gpt-oss-120b — 1,000 requests/day), returning the exact same
// {text} shape so no client code needs to change at all.
//
// Deploy: npx supabase functions deploy gemini-generate
// Secrets:
//   npx supabase secrets set GEMINI_API_KEY=your_gemini_key
//   npx supabase secrets set GROQ_API_KEY=your_groq_key

const GEMINI_MODEL = "gemini-3.5-flash";
const GROQ_MODEL = "openai/gpt-oss-120b"; // current replacement for the
// now-deprecated llama-3.3-70b-versatile (retired June 2026)

async function callGemini(prompt: string, apiKey: string) {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
    },
  );
  return res;
}

async function callGroq(prompt: string, apiKey: string) {
  const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: GROQ_MODEL,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  return res;
}

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

    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    const groqKey = Deno.env.get("GROQ_API_KEY");

    // Try Gemini first.
    if (geminiKey) {
      const geminiRes = await callGemini(prompt, geminiKey);

      if (geminiRes.ok) {
        const data = await geminiRes.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
        return new Response(JSON.stringify({ text, source: "gemini" }), {
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }

      // Only fall back on quota/rate-limit — a real prompt/auth error
      // should surface as-is rather than being masked by a fallback.
      if (geminiRes.status === 429 && groqKey) {
        const groqRes = await callGroq(prompt, groqKey);
        if (groqRes.ok) {
          const data = await groqRes.json();
          const text = data?.choices?.[0]?.message?.content ?? "";
          return new Response(JSON.stringify({ text, source: "groq" }), {
            headers: { ...cors, "Content-Type": "application/json" },
          });
        }
        const groqErr = await groqRes.text();
        return new Response(JSON.stringify({ error: groqErr }), {
          status: groqRes.status,
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }

      const geminiErr = await geminiRes.text();
      return new Response(JSON.stringify({ error: geminiErr }), {
        status: geminiRes.status,
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    // No Gemini key at all — go straight to Groq if available.
    if (groqKey) {
      const groqRes = await callGroq(prompt, groqKey);
      if (groqRes.ok) {
        const data = await groqRes.json();
        const text = data?.choices?.[0]?.message?.content ?? "";
        return new Response(JSON.stringify({ text, source: "groq" }), {
          headers: { ...cors, "Content-Type": "application/json" },
        });
      }
    }

    return new Response(
      JSON.stringify({ error: "No working AI provider configured." }),
      { status: 500, headers: { ...cors, "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});

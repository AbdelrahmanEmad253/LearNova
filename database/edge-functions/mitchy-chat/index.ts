import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function fallbackResponse(reason: string, status = 200) {
  const responseText =
    "I’m here with you. Tell me what part feels unclear, and we’ll break it down step by step.";

  return new Response(
    JSON.stringify({
      ok: true,
      response_text: responseText,
      message: { role: "assistant", content: responseText },
      mitchy: {
        response_text: responseText,
        learning_state: "confused",
        sentiment_score: 0,
        cognitive_load: 0.3,
        suggested_action: "rescue_explanation",
        recommended_format: "Textual",
      },
      metadata: { source: "edge_fallback", used_gemini: false, reason },
    }),
    {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return new Response(JSON.stringify({ ok: false, error: "Method not allowed" }), { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } });

  try {
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const MITCHY_SERVICE_URL = Deno.env.get("MITCHY_SERVICE_URL")!;
    const MITCHY_SERVICE_API_KEY = Deno.env.get("MITCHY_SERVICE_API_KEY")!;

    const authHeader = req.headers.get("Authorization") || "";
    if (!authHeader.startsWith("Bearer ")) return new Response(JSON.stringify({ ok: false, error: "Missing Authorization" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    const supabaseUserClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { global: { headers: { Authorization: authHeader } } });
    const { data: { user }, error: userError } = await supabaseUserClient.auth.getUser();

    if (userError || !user) return new Response(JSON.stringify({ ok: false, error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    const body = await req.json().catch(() => ({}));
    const message = String(body.message || "").trim();
    if (!message) return new Response(JSON.stringify({ ok: false, error: "Message empty" }), { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } });

    const railwayPayload = {
      user_id: user.id,
      user_email: user.email,
      full_name: user.user_metadata?.full_name || user.user_metadata?.name || null,
      message,
      topic_id: body.topic_id ?? null,
      module_id: body.module_id ?? null,
      screen_context: body.screen_context ?? null,
    };

    const railwayResponse = await fetch(`${MITCHY_SERVICE_URL.replace(/\/$/, "")}/mitchy/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-api-key": MITCHY_SERVICE_API_KEY },
      body: JSON.stringify(railwayPayload),
    });

    const railwayText = await railwayResponse.text();
    if (!railwayResponse.ok) return fallbackResponse(`Railway returned ${railwayResponse.status}`);

    const railwayData = JSON.parse(railwayText);
    const responseText = String(railwayData.response_text || railwayData?.message?.content || railwayData?.mitchy?.response_text || "").trim();

    // ── Gamification Injection: Reward XP for Recommendations ────
    // If the AI suggests an action (meaning a recommendation was made), award +20 XP
    if (railwayData.suggested_action && railwayData.suggested_action !== "none") {
      const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
      await supabaseAdmin.rpc("increment_xp", {
        user_id_input: user.id,
        xp_amount: 20,
      });
    }

    return new Response(
      JSON.stringify({
        ...railwayData,
        ok: true,
        message: { role: "assistant", content: responseText, session_id: railwayData?.metadata?.session_id ?? null },
        mitchy: {
          response_text: responseText,
          learning_state: railwayData.learning_state,
          sentiment_score: railwayData.sentiment_score,
          cognitive_load: railwayData.cognitive_load,
          suggested_action: railwayData.suggested_action,
          recommended_format: railwayData.recommended_format_db || railwayData.recommended_format,
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    return fallbackResponse(`Error: ${error instanceof Error ? error.message : String(error)}`);
  }
});
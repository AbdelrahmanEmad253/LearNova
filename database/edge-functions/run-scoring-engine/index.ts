import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

type DiagnosticResultRow = {
  id: string;
  user_id: string;
  test_number: number;
  raw_answers: unknown;
  computed_scores: unknown | null;
  completed_at: string;
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    const scoringServiceUrl = Deno.env.get("SCORING_SERVICE_URL");
    const scoringServiceApiKey = Deno.env.get("SCORING_SERVICE_API_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
      return jsonResponse({ ok: false, error: "Supabase environment variables are missing" }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return jsonResponse({ ok: false, error: "Missing Authorization header" }, 401);

    const supabaseUserClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: userError } = await supabaseUserClient.auth.getUser();
    if (userError || !user) return jsonResponse({ ok: false, error: "Invalid or expired user session" }, 401);

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);
    const requestBody = await req.json().catch(() => ({}));
    const forceRescore = requestBody?.force_rescore === true;

    const { data: diagnosticRows, error: resultsError } = await supabaseAdmin
      .from("diagnostic_test_results")
      .select("id, user_id, test_number, raw_answers, computed_scores, completed_at")
      .eq("user_id", user.id)
      .order("test_number", { ascending: true });

    if (resultsError) return jsonResponse({ ok: false, error: "Failed to fetch diagnostic test results" }, 500);

    const results = (diagnosticRows ?? []) as DiagnosticResultRow[];

    if (results.length < 5) {
      return jsonResponse({ ok: false, error: "Diagnostic tests are not complete yet", tests_found: results.length }, 400);
    }

    const railwayBaseUrl = scoringServiceUrl?.replace(/\/$/, "");
    const railwayUrl = `${railwayBaseUrl}/score/diagnostic-result`;

    const scoringResults: any[] = [];

    for (const row of results) {
      if (row.computed_scores !== null && !forceRescore) {
        scoringResults.push({ result_id: row.id, test_number: row.test_number, skipped: true });
        continue;
      }

      const railwayResponse = await fetch(railwayUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-api-key": scoringServiceApiKey! },
        body: JSON.stringify({ result_id: row.id }),
      });

      if (!railwayResponse.ok) return jsonResponse({ ok: false, error: "Railway scoring failed" }, 500);

      scoringResults.push({ result_id: row.id, test_number: row.test_number, skipped: false });
    }

    const { data: updatedRows } = await supabaseAdmin
      .from("diagnostic_test_results")
      .select("id, test_number, computed_scores")
      .eq("user_id", user.id);

    const scoredCount = (updatedRows ?? []).filter((row) => row.computed_scores !== null).length;
    const allScored = scoredCount >= 5;

    // ── Post-diagnostic initialization ──────────────────────────
    // After all 5 diagnostic tests are scored, initialize the runtime student rows:
    // student_profiles, user_streaks, student_perks, and first challenge schedule.
    let milestoneAwarded = false;
    let initializationResult: Record<string, unknown> | null = null;

    if (allScored) {
      /*
        We expect the Railway scoring service to have written/updated
        student_profiles.assigned_track by now.

        If your Railway scoring endpoint does NOT write student_profiles yet,
        this query will return no assigned_track and the initializer will fail.
      */
      const { data: profileRow, error: profileReadError } = await supabaseAdmin
        .from("student_profiles")
        .select("assigned_track, learning_style, learning_mode, onboarding_complete")
        .eq("user_id", user.id)
        .maybeSingle();

      if (profileReadError) {
        console.error("Failed to read student profile after scoring:", profileReadError);
        return jsonResponse(
          { ok: false, error: "Failed to read student profile after scoring" },
          500,
        );
      }

      const { data: initData, error: initError } = await supabaseAdmin.rpc(
        "initialize_student_after_diagnostic",
        {
          p_user_id: user.id,
          p_assigned_track: profileRow?.assigned_track ?? null,
          p_learning_style: profileRow?.learning_style ?? null,
          p_learning_mode: profileRow?.learning_mode ?? null,
        },
      );

      if (initError) {
        console.error("initialize_student_after_diagnostic failed:", initError);
        return jsonResponse(
          {
            ok: false,
            error: "Student initialization failed after diagnostic scoring",
            details: initError.message,
          },
          500,
        );
      }

      initializationResult = initData as Record<string, unknown>;

      /*
        Award diagnostic completion XP only once.
        If the student was already onboarded, do not award again.
      */
      if (initializationResult?.was_already_onboarded === false) {
        const { error: xpError } = await supabaseAdmin.rpc("increment_xp", {
          user_id_input: user.id,
          xp_amount: 500,
        });

        if (xpError) {
          console.error("Diagnostic milestone XP failed:", xpError);
        } else {
          milestoneAwarded = true;
        }
      }
    }

    return jsonResponse({
      ok: true,
      all_scored: allScored,
      milestone_awarded: milestoneAwarded,
      initialization: initializationResult,
      diagnostic_results: updatedRows,
    });
  } catch (error) {
    return jsonResponse({ ok: false, error: error instanceof Error ? error.message : "Unknown error" }, 500);
  }
});

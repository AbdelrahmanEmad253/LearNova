// ============================================================
// LearNova Edge Function: initialize-track-features
// Location: supabase/functions/initialize-track-features/index.ts
// ============================================================
//
// WHAT THIS FUNCTION DOES (Section 3.3 of the handover):
// Fires exactly once per student, the moment student_profiles.assigned_track
// changes from "Foundation" to "DA"/"DE"/"DS". Called by the Railway scoring
// engine (diagnostic_profile.py) immediately after it writes assigned_track —
// NOT called by Flutter directly.
//
// ATOMICITY: All the real work (grant perks + schedule first challenge +
// notification) happens inside ONE Postgres function, grant_track_features(),
// defined in 2026_06_20_gamification_v2_addendum.sql. Postgres wraps function
// bodies in a transaction automatically, so this is genuinely atomic: either
// everything happens, or nothing does. This Edge Function is just an
// authenticated HTTP wrapper around that one RPC call.
//
// AUTH MODEL: Server-to-server call from Railway, not a Flutter user call.
// Protected by a shared secret header instead of a user JWT, since there's
// no logged-in Flutter session when Railway calls this.
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const INIT_TRACK_FEATURES_API_KEY = Deno.env.get("INIT_TRACK_FEATURES_API_KEY")!;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, x-api-key",
      },
    });
  }

  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  // ── Server-to-server auth via shared secret ──────────────────
  const apiKey = req.headers.get("x-api-key");
  if (!apiKey || apiKey !== INIT_TRACK_FEATURES_API_KEY) {
    return respond({ error: "Unauthorized" }, 401);
  }

  let body: { user_id?: string };
  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { user_id } = body;
  if (!user_id) return respond({ error: "user_id is required" }, 400);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  const { data, error } = await supabase.rpc("grant_track_features", {
    p_user_id: user_id,
  });

  if (error) {
    console.error("grant_track_features RPC error:", error);
    return respond({ error: "Failed to initialize track features" }, 500);
  }

  // grant_track_features returns a JSONB object like:
  // { ok: true, already_initialized: false, perks_granted: true,
  //   first_challenge_scheduled: true, assigned_track: "DA" }
  // or { ok: false, error: "..." } if validation failed inside the function.
  const result = data as Record<string, unknown>;

  if (result.ok === false) {
    return respond(result, 409);
  }

  return respond(result, 200);
});

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

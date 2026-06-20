// ============================================================
// LearNova Edge Function: use-perk
// Location: supabase/functions/use-perk/index.ts
// ============================================================
//
// WHAT THIS FUNCTION DOES (Section 3.4 of the handover):
// Flutter calls this BEFORE rendering an Owl of Wisdom hint or applying
// a Sly Fox 5000 answer elimination. The function decrements the perk
// count and returns ok: true only if the student had a perk available.
// Flutter must only show the perk effect if ok: true comes back.
//
// WHY IT'S CONSUMED ON CALL, NOT ON EXAM SUBMISSION:
// This is deliberate (per the handover NOTE in 3.4): if the count were
// only decremented at exam submission time, a student could use a perk,
// see the hint, then force-quit/refresh the app before submitting and
// effectively get the perk for free next time. Decrementing immediately
// on use closes that loop, at the (accepted) cost that a perk is "spent"
// even if the student never finishes the exam.
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

type PerkType = "owl_hint" | "sly_fox";
const VALID_PERK_TYPES: PerkType[] = ["owl_hint", "sly_fox"];

// Maps the API-facing perk_type to the actual column name in student_perks.
const PERK_COLUMN: Record<PerkType, string> = {
  owl_hint: "owl_hint_count",
  sly_fox: "sly_fox_count",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  if (req.method !== "POST") return respond({ error: "Method not allowed" }, 405);

  let body: { perk_type?: string; question_id?: string };
  try {
    body = await req.json();
  } catch {
    return respond({ error: "Invalid JSON body" }, 400);
  }

  const { perk_type, question_id } = body;

  if (!perk_type || !VALID_PERK_TYPES.includes(perk_type as PerkType)) {
    return respond({ ok: false, error: "perk_type must be 'owl_hint' or 'sly_fox'" }, 400);
  }
  if (!question_id) {
    return respond({ ok: false, error: "question_id is required" }, 400);
  }

  // ── Auth ──────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return respond({ ok: false, error: "Missing Authorization" }, 401);

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authError } = await clientForAuth.auth.getUser();
  if (authError || !user) return respond({ ok: false, error: "Unauthorized" }, 401);
  const studentId = user.id;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  // ── Read current perk balance ────────────────────────────────
  const { data: perks, error: perksError } = await supabase
    .from("student_perks")
    .select("owl_hint_count, sly_fox_count")
    .eq("user_id", studentId)
    .maybeSingle();

  if (perksError) {
    console.error("student_perks read error:", perksError);
    return respond({ ok: false, error: "Failed to read perk balance" }, 500);
  }

  if (!perks) {
    // No row at all means track features were never initialized for this
    // student (e.g. they're still on Foundation, or initialize-track-features
    // hasn't fired yet). Treat as zero perks available.
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  const column = PERK_COLUMN[perk_type as PerkType];
  const currentCount = column === "owl_hint_count" ? perks.owl_hint_count : perks.sly_fox_count;

  if (currentCount <= 0) {
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  // ── Decrement ──────────────────────────────────────────────
  const newCount = currentCount - 1;
  const updatePayload: Record<string, unknown> = { updated_at: new Date().toISOString() };
  updatePayload[column] = newCount;

  const { error: updateError } = await supabase
    .from("student_perks")
    .update(updatePayload)
    .eq("user_id", studentId)
    // Extra safety: only decrement if the count we read is still what's
    // in the DB, guarding (loosely) against a race of two rapid calls.
    .eq(column, currentCount);

  if (updateError) {
    console.error("student_perks update error:", updateError);
    return respond({ ok: false, error: "Failed to use perk" }, 500);
  }

  return respond({ ok: true, remaining: newCount, perk_type, question_id }, 200);
});

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

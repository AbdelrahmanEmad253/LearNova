// ============================================================
// LearNova Edge Function: use-perk
// Location: supabase/functions/use-perk/index.ts
// ============================================================
//
// Purpose:
// - Allows students to use Owl of Wisdom and Sly Fox perks on MODULE MCQ exam questions.
// - Reads module_assessment_questions only.
// - Does NOT support level written questions, diagnostic questions, or weekly challenge questions.
// - Deducts the perk only after confirming the question is a valid module MCQ question
//   and the perk effect can be returned safely.
//
// Fix in this version:
// - Sly Fox can now match correct_answer more flexibly.
// - Supported correct_answer formats include:
//   A / B / C / D
//   a / b / c / d
//   A. / B) / Option A / option_b
//   0-based numeric index for array options: 0, 1, 2, 3
//   1-based numeric index for array options: 1, 2, 3, 4
//   full option text
//   object values like { "answer": "B" } or { "correct_answer": "B" }
// - Options can be:
//   ["A text", "B text", "C text"]
//   { "A": "A text", "B": "B text" }
//   { "A": { "text": "A text" }, "B": { "text": "B text" } }
//   [{ "text": "A text" }, { "text": "B text" }]
//   values with embedded correctness flags like { "text": "...", "is_correct": true }
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

type PerkType = "owl_hint" | "sly_fox";
const VALID_PERK_TYPES: PerkType[] = ["owl_hint", "sly_fox"];

const PERK_COLUMN: Record<PerkType, "owl_hint_count" | "sly_fox_count"> = {
  owl_hint: "owl_hint_count",
  sly_fox: "sly_fox_count",
};

type ModuleQuestion = {
  id: string;
  question_text: string | null;
  options: unknown;
  correct_answer: unknown;
  mitchy_hint?: string | null;
};

type OptionCandidate = {
  key: string;
  keyNormalized: string;
  index: number;
  value: string;
  valueNormalized: string;
  raw: unknown;
  embeddedCorrect: boolean;
  isCorrect: boolean;
};

type ParsedCorrectAnswer = {
  raw: unknown;
  normalized: string;
  possibleKeys: Set<string>;
  possibleTexts: Set<string>;
  possibleIndexesZeroBased: Set<number>;
  possibleIndexesOneBased: Set<number>;
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

  if (req.method !== "POST") {
    return respond({ ok: false, error: "Method not allowed" }, 405);
  }

  let body: { perk_type?: string; question_id?: string };

  try {
    body = await req.json();
  } catch {
    return respond({ ok: false, error: "Invalid JSON body" }, 400);
  }

  const perkType = body.perk_type as PerkType | undefined;
  const questionId = body.question_id;

  if (!perkType || !VALID_PERK_TYPES.includes(perkType)) {
    return respond({ ok: false, error: "perk_type must be 'owl_hint' or 'sly_fox'" }, 400);
  }

  if (!questionId) {
    return respond({ ok: false, error: "question_id is required" }, 400);
  }

  // ── Auth ──────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");

  if (!authHeader) {
    return respond({ ok: false, error: "Missing Authorization" }, 401);
  }

  const clientForAuth = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: authError,
  } = await clientForAuth.auth.getUser();

  if (authError || !user) {
    return respond({ ok: false, error: "Unauthorized" }, 401);
  }

  const studentId = user.id;
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  // ── Read the module MCQ question first ─────────────────────
  const { data: question, error: questionError } = await supabase
    .from("module_assessment_questions")
    .select("id, question_text, options, correct_answer, mitchy_hint")
    .eq("id", questionId)
    .maybeSingle();

  if (questionError) {
    console.error("module_assessment_questions read error:", questionError);
    return respond(
      {
        ok: false,
        error: "Failed to read module MCQ question",
        details: questionError.message,
      },
      500,
    );
  }

  if (!question) {
    return respond(
      {
        ok: false,
        error: "This perk can only be used on module MCQ exam questions.",
        reason: "question_not_found_in_module_assessment_questions",
        question_id: questionId,
      },
      200,
    );
  }

  const moduleQuestion = question as ModuleQuestion;

  // ── Build the perk effect BEFORE decrementing ───────────────
  const effectResult =
    perkType === "owl_hint"
      ? buildOwlHintEffect(moduleQuestion)
      : buildSlyFoxEffect(moduleQuestion);

  if (!effectResult.ok) {
    return respond(
      {
        ok: false,
        error: effectResult.error,
        reason: effectResult.reason,
        question_id: questionId,
        question_source: "module_assessment_questions",
        debug: effectResult.debug ?? null,
      },
      200,
    );
  }

  // ── Read current perk balance ───────────────────────────────
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
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  const column = PERK_COLUMN[perkType];
  const currentCount = Number(perks[column] ?? 0);

  if (!Number.isFinite(currentCount) || currentCount <= 0) {
    return respond({ ok: false, error: "No perks remaining" }, 200);
  }

  // ── Decrement only after successful validation/effect build ─
  const newCount = currentCount - 1;

  const updatePayload: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };
  updatePayload[column] = newCount;

  const { data: updatedRows, error: updateError } = await supabase
    .from("student_perks")
    .update(updatePayload)
    .eq("user_id", studentId)
    .eq(column, currentCount)
    .select("user_id");

  if (updateError) {
    console.error("student_perks update error:", updateError);
    return respond({ ok: false, error: "Failed to use perk" }, 500);
  }

  if (!updatedRows || updatedRows.length === 0) {
    return respond(
      {
        ok: false,
        error: "Perk balance changed. Please refresh and try again.",
        reason: "perk_balance_race_condition",
      },
      409,
    );
  }

  return respond(
    {
      ok: true,
      remaining: newCount,
      perk_type: perkType,
      question_id: questionId,
      question_source: "module_assessment_questions",
      effect: effectResult.effect,
    },
    200,
  );
});

function buildOwlHintEffect(question: ModuleQuestion):
  | { ok: true; effect: { type: "hint"; hint: string } }
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  const hint = typeof question.mitchy_hint === "string" ? question.mitchy_hint.trim() : "";

  if (!hint) {
    return {
      ok: false,
      error: "No Owl of Wisdom hint is available for this module question.",
      reason: "missing_mitchy_hint",
    };
  }

  return {
    ok: true,
    effect: {
      type: "hint",
      hint,
    },
  };
}

function buildSlyFoxEffect(question: ModuleQuestion):
  | {
      ok: true;
      effect: {
        type: "eliminate_option";
        eliminated_option_key: string;
        eliminated_option_value: string;
      };
    }
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  const parsedOptions = parseOptions(question.options, question.correct_answer);

  if (!parsedOptions.ok) {
    return {
      ok: false,
      error: parsedOptions.error,
      reason: parsedOptions.reason,
      debug: parsedOptions.debug,
    };
  }

  const wrongOptions = parsedOptions.options.filter((option) => !option.isCorrect);

  if (wrongOptions.length === 0) {
    return {
      ok: false,
      error: "Sly Fox could not safely find an incorrect option to eliminate.",
      reason: "no_wrong_options_found",
      debug: {
        options: parsedOptions.options.map(debugOption),
      },
    };
  }

  const selectedWrong = wrongOptions[randomIndex(wrongOptions.length)];

  return {
    ok: true,
    effect: {
      type: "eliminate_option",
      eliminated_option_key: selectedWrong.key,
      eliminated_option_value: selectedWrong.value,
    },
  };
}

function parseOptions(
  rawOptions: unknown,
  rawCorrectAnswer: unknown,
):
  | { ok: true; options: OptionCandidate[] }
  | { ok: false; error: string; reason: string; debug?: Record<string, unknown> } {
  let options = rawOptions;

  if (typeof options === "string") {
    try {
      options = JSON.parse(options);
    } catch {
      return {
        ok: false,
        error: "Sly Fox requires options to be valid JSON.",
        reason: "options_not_json",
        debug: {
          raw_options_type: typeof rawOptions,
          raw_options_preview: String(rawOptions).slice(0, 500),
        },
      };
    }
  }

  const candidates: OptionCandidate[] = [];

  if (Array.isArray(options)) {
    options.forEach((value, index) => {
      const key = extractOptionKeyFromRaw(value) || indexToOptionKey(index);
      const textValue = extractOptionText(value);
      candidates.push({
        key,
        keyNormalized: normalizeKey(key),
        index,
        value: textValue,
        valueNormalized: normalizeText(textValue),
        raw: value,
        embeddedCorrect: extractEmbeddedCorrectFlag(value),
        isCorrect: false,
      });
    });
  } else if (options && typeof options === "object") {
    Object.entries(options as Record<string, unknown>).forEach(([key, value], index) => {
      const extractedKey = extractOptionKeyFromRaw(value) || key;
      const textValue = extractOptionText(value);
      candidates.push({
        key: extractedKey,
        keyNormalized: normalizeKey(extractedKey),
        index,
        value: textValue,
        valueNormalized: normalizeText(textValue),
        raw: value,
        embeddedCorrect: extractEmbeddedCorrectFlag(value),
        isCorrect: false,
      });
    });
  } else {
    return {
      ok: false,
      error: "Sly Fox requires MCQ options on the module question.",
      reason: "missing_or_invalid_options",
      debug: {
        raw_options_type: typeof rawOptions,
      },
    };
  }

  const usableCandidates = candidates.filter((option) => option.value.trim().length > 0);

  if (usableCandidates.length < 2) {
    return {
      ok: false,
      error: "Sly Fox requires at least two usable options.",
      reason: "not_enough_options",
      debug: {
        options_count: candidates.length,
        usable_options_count: usableCandidates.length,
      },
    };
  }

  const correct = parseCorrectAnswer(rawCorrectAnswer, usableCandidates.length);

  // First preference: embedded correctness flag inside options.
  const embeddedCorrectCount = usableCandidates.filter((option) => option.embeddedCorrect).length;
  if (embeddedCorrectCount === 1) {
    usableCandidates.forEach((option) => {
      option.isCorrect = option.embeddedCorrect;
    });

    return { ok: true, options: usableCandidates };
  }

  if (!correct.normalized && correct.possibleKeys.size === 0 && correct.possibleTexts.size === 0) {
    return {
      ok: false,
      error: "Sly Fox requires a correct_answer value on the module question.",
      reason: "missing_correct_answer",
      debug: {
        raw_correct_answer: rawCorrectAnswer,
        options: usableCandidates.map(debugOption),
      },
    };
  }

  usableCandidates.forEach((option) => {
    option.isCorrect = doesOptionMatchCorrectAnswer(option, correct, usableCandidates);
  });

  let correctCount = usableCandidates.filter((option) => option.isCorrect).length;

  /*
    Final fallback for common old-data shape:
    correct_answer stores the literal answer text but with a leading label like:
      "A. Central tendency"
      "B) Variance"
    If no match happened above, compare with option text after stripping labels.
  */
  if (correctCount === 0) {
    const strippedCorrect = stripLeadingOptionLabel(correct.normalized);
    usableCandidates.forEach((option) => {
      if (stripLeadingOptionLabel(option.valueNormalized) === strippedCorrect) {
        option.isCorrect = true;
      }
    });
    correctCount = usableCandidates.filter((option) => option.isCorrect).length;
  }

  if (correctCount === 0) {
    return {
      ok: false,
      error: "Sly Fox could not safely identify the correct answer, so it will not eliminate any option.",
      reason: "correct_answer_not_matched_to_options",
      debug: {
        raw_correct_answer: rawCorrectAnswer,
        parsed_correct_answer: debugCorrectAnswer(correct),
        options: usableCandidates.map(debugOption),
      },
    };
  }

  if (correctCount > 1) {
    return {
      ok: false,
      error: "Sly Fox found more than one option matching the correct answer, so it will not eliminate any option.",
      reason: "multiple_correct_answer_matches",
      debug: {
        raw_correct_answer: rawCorrectAnswer,
        parsed_correct_answer: debugCorrectAnswer(correct),
        options: usableCandidates.map(debugOption),
      },
    };
  }

  return { ok: true, options: usableCandidates };
}

function parseCorrectAnswer(rawCorrectAnswer: unknown, optionCount: number): ParsedCorrectAnswer {
  const extracted = extractCorrectAnswerValue(rawCorrectAnswer);
  const normalized = normalizeText(extracted);

  const possibleKeys = new Set<string>();
  const possibleTexts = new Set<string>();
  const possibleIndexesZeroBased = new Set<number>();
  const possibleIndexesOneBased = new Set<number>();

  if (normalized) {
    possibleTexts.add(normalized);

    const key = normalizeKey(normalized);
    if (key) possibleKeys.add(key);

    const optionKeyFromPhrase = extractOptionKeyFromPhrase(normalized);
    if (optionKeyFromPhrase) possibleKeys.add(optionKeyFromPhrase);

    const numberMatch = normalized.match(/^\d+$/);
    if (numberMatch) {
      const n = Number(normalized);

      if (Number.isInteger(n)) {
        if (n >= 0 && n < optionCount) possibleIndexesZeroBased.add(n);
        if (n >= 1 && n <= optionCount) possibleIndexesOneBased.add(n - 1);
      }
    }
  }

  return {
    raw: rawCorrectAnswer,
    normalized,
    possibleKeys,
    possibleTexts,
    possibleIndexesZeroBased,
    possibleIndexesOneBased,
  };
}

function extractCorrectAnswerValue(value: unknown): string {
  if (value === null || value === undefined) return "";

  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (typeof value === "object") {
    const objectValue = value as Record<string, unknown>;

    const preferredFields = [
      "correct_answer",
      "correctAnswer",
      "answer",
      "key",
      "option",
      "label",
      "value",
      "text",
    ];

    for (const field of preferredFields) {
      const fieldValue = objectValue[field];
      if (fieldValue !== null && fieldValue !== undefined && String(fieldValue).trim()) {
        return String(fieldValue);
      }
    }

    try {
      return JSON.stringify(value);
    } catch {
      return String(value);
    }
  }

  return String(value);
}

function doesOptionMatchCorrectAnswer(
  option: OptionCandidate,
  correct: ParsedCorrectAnswer,
  allOptions: OptionCandidate[],
): boolean {
  if (correct.possibleKeys.has(option.keyNormalized)) return true;
  if (correct.possibleTexts.has(option.valueNormalized)) return true;

  /*
    Numeric correct_answer support:
    - If correct_answer is 0, 1, 2, 3, it may be zero-based.
    - If correct_answer is 1, 2, 3, 4, it may be one-based.
    To avoid eliminating the true answer incorrectly when numeric labels are ambiguous,
    only use numeric index fallback when it points to exactly one candidate and
    no option text is exactly equal to that numeric value.
  */
  const numericTextAlreadyExistsAsOption = allOptions.some(
    (candidate) => correct.possibleTexts.has(candidate.valueNormalized),
  );

  if (!numericTextAlreadyExistsAsOption) {
    if (correct.possibleIndexesZeroBased.has(option.index)) return true;

    // Only allow one-based fallback when zero-based did not already identify a different option.
    if (
      correct.possibleIndexesZeroBased.size === 0 &&
      correct.possibleIndexesOneBased.has(option.index)
    ) {
      return true;
    }
  }

  return false;
}

function extractOptionText(value: unknown): string {
  if (value === null || value === undefined) return "";

  if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (typeof value === "object") {
    const objectValue = value as Record<string, unknown>;

    const preferredFields = [
      "text",
      "option_text",
      "optionText",
      "label",
      "value",
      "answer",
      "content",
      "title",
    ];

    for (const field of preferredFields) {
      const fieldValue = objectValue[field];
      if (fieldValue !== null && fieldValue !== undefined && String(fieldValue).trim()) {
        return String(fieldValue);
      }
    }

    try {
      return JSON.stringify(value);
    } catch {
      return String(value);
    }
  }

  return String(value);
}

function extractOptionKeyFromRaw(value: unknown): string | null {
  if (!value || typeof value !== "object") return null;

  const objectValue = value as Record<string, unknown>;
  const fields = ["key", "option_key", "optionKey", "letter", "label"];

  for (const field of fields) {
    const fieldValue = objectValue[field];
    if (fieldValue !== null && fieldValue !== undefined && String(fieldValue).trim()) {
      return String(fieldValue);
    }
  }

  return null;
}

function extractEmbeddedCorrectFlag(value: unknown): boolean {
  if (!value || typeof value !== "object") return false;

  const objectValue = value as Record<string, unknown>;
  const fields = ["is_correct", "isCorrect", "correct", "is_answer", "isAnswer"];

  for (const field of fields) {
    const fieldValue = objectValue[field];

    if (fieldValue === true) return true;

    if (typeof fieldValue === "string") {
      const normalized = fieldValue.trim().toLowerCase();
      if (["true", "yes", "1", "correct"].includes(normalized)) return true;
    }

    if (fieldValue === 1) return true;
  }

  return false;
}

function normalizeKey(value: string): string {
  let text = String(value).trim().toLowerCase();

  text = text.replace(/^answer\s*:\s*/i, "").trim();
  text = text.replace(/^correct\s*answer\s*:\s*/i, "").trim();
  text = text.replace(/^option\s+/i, "").trim();
  text = text.replace(/^option[_-]/i, "").trim();

  const singleLetterMatch = text.match(/^([a-z])[\.\)]?$/);
  if (singleLetterMatch) return singleLetterMatch[1];

  return "";
}

function extractOptionKeyFromPhrase(value: string): string {
  let text = String(value).trim().toLowerCase();

  text = text.replace(/^answer\s*:\s*/i, "").trim();
  text = text.replace(/^correct\s*answer\s*:\s*/i, "").trim();

  const patterns = [
    /^option\s+([a-z])$/,
    /^option[_-]([a-z])$/,
    /^([a-z])[\.\)]\s+.+$/,
    /^([a-z])\s*[-:]\s+.+$/,
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match) return match[1];
  }

  return "";
}

function normalizeText(value: unknown): string {
  if (value === null || value === undefined) return "";

  let text = String(value).trim().toLowerCase();

  text = text.replace(/^answer\s*:\s*/i, "").trim();
  text = text.replace(/^correct\s*answer\s*:\s*/i, "").trim();
  text = text.replace(/\s+/g, " ");

  return text;
}

function stripLeadingOptionLabel(value: string): string {
  return String(value)
    .trim()
    .toLowerCase()
    .replace(/^answer\s*:\s*/i, "")
    .replace(/^correct\s*answer\s*:\s*/i, "")
    .replace(/^option\s+[a-z][\.\)\-:]*\s*/i, "")
    .replace(/^option[_-][a-z][\.\)\-:]*\s*/i, "")
    .replace(/^[a-z][\.\)\-:]\s*/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

function stringifySet(set: Set<string | number>): Array<string | number> {
  return Array.from(set.values());
}

function debugCorrectAnswer(correct: ParsedCorrectAnswer): Record<string, unknown> {
  return {
    normalized: correct.normalized,
    possible_keys: stringifySet(correct.possibleKeys),
    possible_texts: stringifySet(correct.possibleTexts),
    possible_indexes_zero_based: stringifySet(correct.possibleIndexesZeroBased),
    possible_indexes_one_based: stringifySet(correct.possibleIndexesOneBased),
  };
}

function debugOption(option: OptionCandidate): Record<string, unknown> {
  return {
    key: option.key,
    key_normalized: option.keyNormalized,
    index: option.index,
    value: option.value,
    value_normalized: option.valueNormalized,
    embedded_correct: option.embeddedCorrect,
    is_correct: option.isCorrect,
  };
}

function indexToOptionKey(index: number): string {
  return String.fromCharCode("A".charCodeAt(0) + index);
}

function randomIndex(length: number): number {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return array[0] % length;
}

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

import 'package:learnova/features/assessment/domain/entities/exam_perk.dart';

// ──────────────────────────────────────────────────
// Result returned by the use-perk Edge Function
// ──────────────────────────────────────────────────

class PerkUseResult {
  final bool ok;

  /// Hint text returned by the Owl of Wisdom perk (null for other perks).
  final String? hint;

  /// The option index eliminated by the Sly Fox perk (null for other perks).
  final int? eliminatedOptionIndex;

  /// Remaining count for the perk type that was just used.
  final int remaining;

  /// Error message when [ok] is false.
  final String? error;

  const PerkUseResult({
    required this.ok,
    this.hint,
    this.eliminatedOptionIndex,
    required this.remaining,
    this.error,
  });

  factory PerkUseResult.fromJson(Map<String, dynamic> json) {
    return PerkUseResult(
      ok: json['ok'] as bool? ?? false,
      hint: json['hint'] as String?,
      eliminatedOptionIndex: json['eliminated_option_index'] as int?,
      remaining: (json['remaining'] as int?) ?? 0,
      error: json['error'] as String?,
    );
  }
}

// ──────────────────────────────────────────────────
// Per-question perk usage record
// ──────────────────────────────────────────────────

/// Tracks what effects have been applied to a single question.
class QuestionPerkEffects {
  /// Hint text revealed by the Owl of Wisdom (null if not used).
  final String? hint;

  /// Option index eliminated by the Sly Fox (null if not used).
  final int? eliminatedOptionIndex;

  /// Set of perk IDs already cast on this question.
  final Set<String> usedPerkIds;

  const QuestionPerkEffects({
    this.hint,
    this.eliminatedOptionIndex,
    this.usedPerkIds = const {},
  });

  QuestionPerkEffects copyWith({
    String? hint,
    int? eliminatedOptionIndex,
    Set<String>? usedPerkIds,
  }) {
    return QuestionPerkEffects(
      hint: hint ?? this.hint,
      eliminatedOptionIndex:
          eliminatedOptionIndex ?? this.eliminatedOptionIndex,
      usedPerkIds: usedPerkIds ?? this.usedPerkIds,
    );
  }
}

// ──────────────────────────────────────────────────
// Overall deck state
// ──────────────────────────────────────────────────

class PerkDeckState {
  /// The list of perks available in the deck.
  final List<ExamPerk> perks;

  /// Remaining inventory: perkId → count.
  final Map<String, int> remaining;

  /// Per-question effects: questionId → effects.
  final Map<String, QuestionPerkEffects> questionEffects;

  /// Which perk is currently being cast (null when idle).
  final String? castingPerkId;

  /// Non-null when the last cast resulted in an error.
  final String? lastError;

  /// Whether the perk deck has been loaded from the server.
  final bool isInitialised;

  /// Set to the perk ID that just succeeded — drives the cast-effect animation.
  /// Cleared after the animation completes.
  final String? justCastPerkId;

  const PerkDeckState({
    this.perks = const [],
    this.remaining = const {},
    this.questionEffects = const {},
    this.castingPerkId,
    this.lastError,
    this.isInitialised = false,
    this.justCastPerkId,
  });

  PerkDeckState copyWith({
    List<ExamPerk>? perks,
    Map<String, int>? remaining,
    Map<String, QuestionPerkEffects>? questionEffects,
    String? castingPerkId,
    String? lastError,
    bool? isInitialised,
    String? justCastPerkId,
    bool clearCasting = false,
    bool clearError = false,
    bool clearJustCast = false,
  }) {
    return PerkDeckState(
      perks: perks ?? this.perks,
      remaining: remaining ?? this.remaining,
      questionEffects: questionEffects ?? this.questionEffects,
      castingPerkId: clearCasting ? null : (castingPerkId ?? this.castingPerkId),
      lastError: clearError ? null : (lastError ?? this.lastError),
      isInitialised: isInitialised ?? this.isInitialised,
      justCastPerkId:
          clearJustCast ? null : (justCastPerkId ?? this.justCastPerkId),
    );
  }

  // ── Convenience getters ──

  /// Whether a specific perk has already been used on [questionId].
  bool isPerkUsedOnQuestion(String perkId, String questionId) {
    return questionEffects[questionId]?.usedPerkIds.contains(perkId) ?? false;
  }

  /// Hint text for [questionId], or null.
  String? hintForQuestion(String questionId) =>
      questionEffects[questionId]?.hint;

  /// Eliminated option index for [questionId], or null.
  int? eliminatedOptionForQuestion(String questionId) =>
      questionEffects[questionId]?.eliminatedOptionIndex;

  /// Remaining count for a perk.
  int remainingForPerk(String perkId) => remaining[perkId] ?? 0;
}

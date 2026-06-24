import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:learnova/features/assessment/data/datasources/perk_remote_data_source.dart';
import 'package:learnova/features/assessment/domain/entities/exam_perk.dart';
import 'package:learnova/features/assessment/domain/entities/perk_state.dart';

/// Manages perk deck state for a single exam session.
///
/// Responsibilities:
/// * Load initial inventory from [PerkRemoteDataSource].
/// * Cast a perk (call API → apply visual effect on success).
/// * Prevent double-stacking (same perk on same question).
/// * Track per-question effects (hints, eliminated options).
class PerkDeckViewModel extends StateNotifier<PerkDeckState> {
  final PerkRemoteDataSource _dataSource;

  PerkDeckViewModel(this._dataSource) : super(const PerkDeckState());

  // ── Initialisation ───────────────────────────────────

  /// Call once when the exam screen mounts.
  Future<void> initialise() async {
    final inventory = await _dataSource.fetchPerkInventory();
    state = state.copyWith(
      perks: [OwlOfWisdomPerk(), SlyFoxPerk()],
      remaining: inventory,
      isInitialised: true,
    );
  }

  // ── Cast perk ────────────────────────────────────────

  /// Attempts to cast [perk] on question [questionId].
  ///
  /// Returns `true` on success, `false` otherwise.
  /// All state transitions are reactive — the UI rebuilds automatically.
  Future<bool> castPerk({
    required ExamPerk perk,
    required String questionId,
    required String currentQuestionType,
  }) async {
    // ── Guard: perk not applicable to this question type
    if (!perk.canBeUsedOn(currentQuestionType)) {
      state = state.copyWith(
        lastError: '${perk.name} can only be used on MCQ questions.',
        clearCasting: true,
      );
      return false;
    }

    // ── Guard: already used this perk on this question
    if (state.isPerkUsedOnQuestion(perk.id, questionId)) {
      state = state.copyWith(
        lastError: '${perk.name} has already been used on this question.',
        clearCasting: true,
      );
      return false;
    }

    // ── Guard: no remaining uses
    if (state.remainingForPerk(perk.id) <= 0) {
      state = state.copyWith(
        lastError: 'No ${perk.name} perks remaining.',
        clearCasting: true,
      );
      return false;
    }

    // ── Guard: another perk is currently being cast
    if (state.castingPerkId != null) return false;

    // ── Set loading state
    state = state.copyWith(
      castingPerkId: perk.id,
      clearError: true,
    );

    // ── Call API
    final result = await _dataSource.usePerk(
      perkType: perk.apiKey,
      questionId: questionId,
    );

    if (!result.ok) {
      state = state.copyWith(
        lastError: result.error ?? 'Perk cast failed.',
        clearCasting: true,
      );
      return false;
    }

    // ── Apply effect
    final currentEffects =
        state.questionEffects[questionId] ?? const QuestionPerkEffects();

    final updatedEffects = currentEffects.copyWith(
      hint: result.hint ?? currentEffects.hint,
      eliminatedOptionKey:
          result.eliminatedOptionKey ?? currentEffects.eliminatedOptionKey,
      eliminatedOptionValue:
          result.eliminatedOptionValue ?? currentEffects.eliminatedOptionValue,
      usedPerkIds: {...currentEffects.usedPerkIds, perk.id},
    );

    final updatedQuestionEffects = Map<String, QuestionPerkEffects>.from(
      state.questionEffects,
    )..[questionId] = updatedEffects;

    final updatedRemaining = Map<String, int>.from(state.remaining)
      ..[perk.id] = result.remaining;

    state = state.copyWith(
      questionEffects: updatedQuestionEffects,
      remaining: updatedRemaining,
      justCastPerkId: perk.id,
      clearCasting: true,
    );

    debugPrint(
      '[PerkVM] ${perk.name} cast on $questionId → remaining: ${result.remaining}',
    );

    return true;
  }

  // ── Clear transient state ────────────────────────────

  /// Clear the "just cast" flag after the animation plays.
  void clearJustCast() {
    state = state.copyWith(clearJustCast: true);
  }

  /// Clear any error (e.g. after showing a SnackBar).
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

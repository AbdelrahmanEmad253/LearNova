import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:learnova/features/assessment/domain/entities/perk_state.dart';

/// Data source responsible for perk-related Supabase operations.
///
/// Handles:
/// * Fetching initial perk inventory from `student_perks`.
/// * Invoking the `use-perk` Edge Function.
class PerkRemoteDataSource {
  final SupabaseClient _client;

  PerkRemoteDataSource(this._client);

  // ── Fetch current inventory ──────────────────────────

  /// Returns `{ owl_hint: int, sly_fox: int }` for the signed-in user.
  /// If no row exists yet, returns zeroes.
  Future<Map<String, int>> fetchPerkInventory() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {'owl_hint': 0, 'sly_fox': 0};

    try {
      final row = await _client
          .from('student_perks')
          .select('owl_hint_count, sly_fox_count')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) return {'owl_hint': 0, 'sly_fox': 0};

      return {
        'owl_hint': (row['owl_hint_count'] as int?) ?? 0,
        'sly_fox': (row['sly_fox_count'] as int?) ?? 0,
      };
    } catch (e) {
      debugPrint('[PerkDS] fetchPerkInventory error: $e');
      return {'owl_hint': 0, 'sly_fox': 0};
    }
  }

  // ── Use a perk via Edge Function ─────────────────────

  /// Calls `POST /functions/v1/use-perk`.
  ///
  /// The Edge Function validates inventory, decrements the count, and returns
  /// the perk effect payload.
  Future<PerkUseResult> usePerk({
    required String perkType,
    required String questionId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'use-perk',
        body: {
          'perk_type': perkType,
          'question_id': questionId,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PerkUseResult.fromJson(data);
      }

      return const PerkUseResult(
        ok: false,
        remaining: 0,
        error: 'Invalid response from server.',
      );
    } catch (e) {
      debugPrint('[PerkDS] usePerk error: $e');
      return PerkUseResult(
        ok: false,
        remaining: 0,
        error: e.toString(),
      );
    }
  }
}

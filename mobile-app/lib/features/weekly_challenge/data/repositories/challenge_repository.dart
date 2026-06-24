import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/weekly_challenge/data/models/challenge_schedule_model.dart';
import 'package:learnova/features/weekly_challenge/data/models/weekly_challenge_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  final supabase = ref.read(supabaseClientProvider);
  return ChallengeRepository(supabase);
});

class ChallengeRepository {
  final SupabaseClient _supabase;

  ChallengeRepository(this._supabase);

  Future<ChallengeScheduleModel?> getCurrentChallengeSchedule() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('student_challenge_schedule')
        .select('*, weekly_challenges(*)')
        .eq('user_id', userId)
        .order('available_from', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return ChallengeScheduleModel.fromJson(response);
  }
}

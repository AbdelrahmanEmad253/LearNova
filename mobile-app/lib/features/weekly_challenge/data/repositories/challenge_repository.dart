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

    // Uncomment this for actual Supabase fetch:
    /*
    final response = await _supabase
        .from('student_challenge_schedule')
        .select('*, weekly_challenges(*)')
        .eq('user_id', userId)
        .order('available_from', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return ChallengeScheduleModel.fromJson(response);
    */

    // --- MOCK DATA FOR UI TESTING ---
    await Future.delayed(const Duration(milliseconds: 800));

    // To test different states, change the `status` and dates below.
    // States: 'locked', 'available', 'started', 'passed', 'failed', 'expired'
    return ChallengeScheduleModel(
      id: 'mock-sched-123',
      userId: userId,
      challengeId: 'mock-chal-123',
      status: 'available', // <-- Change this to test UI
      assignedAt: DateTime.now().subtract(const Duration(days: 1)),
      availableFrom: DateTime.now().subtract(const Duration(minutes: 5)),
      expiresAt: DateTime.now().add(const Duration(days: 2)),
      currentAttempts: 0,
      passed: false,
      bestScore: null,
      challengeDetails: const WeeklyChallengeModel(
        id: 'mock-chal-123',
        moduleId: 'mod-123',
        title: 'Mastering Pointers in C++',
        description: 'A 15-question challenge covering advanced memory management and pointer arithmetic.',
        isActive: true,
        xpRewardEasy: 20,
        xpRewardMid: 50,
        xpRewardHard: 100,
      ),
    );
  }
}

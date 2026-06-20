import 'package:learnova/features/auth/data/models/student_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for the `student_profiles` table.
class StudentProfileRemoteDataSource {
  final SupabaseClient _client;

  const StudentProfileRemoteDataSource(this._client);

  /// Fetch the current user's profile. Returns null if not found.
  Future<StudentProfileModel?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final raw = await _client
          .from('student_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (raw == null) return null;
      return StudentProfileModel.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  /// Update the learning style for the current user.
  Future<bool> updateLearningStyle(String learningStyle) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('student_profiles').upsert({
        'user_id': user.id,
        'learning_style': learningStyle,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Increment XP for the current user.
  Future<bool> addXp(int amount) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // Use RPC or raw update with current value.
      final profile = await fetchProfile();
      if (profile == null) return false;

      await _client.from('student_profiles').update({
        'xp_total': profile.totalXp + amount,
      }).eq('user_id', user.id);

      return true;
    } catch (_) {
      return false;
    }
  }
}

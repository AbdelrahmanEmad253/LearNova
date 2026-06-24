import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ProfileRemoteDataSource(this._supabaseClient);

  Future<void> upsertReminderSettings({
    required String time,
    required bool isEmail,
    required bool isPush,
  }) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    await _supabaseClient.from('user_reminders').upsert({
      'user_id': userId,
      'reminder_time': time,
      'is_email_enabled': isEmail,
      'is_push_enabled': isPush,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<Map<String, dynamic>?> getReminderSettings() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    final response = await _supabaseClient
        .from('user_reminders')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
        
    return response;
  }
}

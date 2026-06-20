import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsService {
  final SupabaseClient _client;

  const AchievementsService(this._client);

  Future<List<Map<String, dynamic>>> fetchUserAchievements() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    
    try {
      final response = await _client
          .from('user_achievements')
          .select('unlocked_at, achievements_dictionary(*)')
          .eq('user_id', user.id);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[AchievementsService] fetchUserAchievements error: $e');
      return [];
    }
  }
}

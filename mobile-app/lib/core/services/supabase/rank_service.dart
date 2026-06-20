import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankService {
  final SupabaseClient _client;

  const RankService(this._client);

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final response = await _client
          .from('student_profiles')
          .select('user_id, xp_total, users(full_name, avatar_url)')
          .order('xp_total', ascending: false)
          .limit(100);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('[RankService] fetchLeaderboard error: $e');
      return [];
    }
  }

  Future<int?> fetchCurrentUserRank() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    
    try {
      // Find the user's position in the top 100 leaderboard
      final leaderboard = await fetchLeaderboard();
      final index = leaderboard.indexWhere((element) => element['user_id'] == user.id);
      
      if (index != -1) {
        return index + 1; // Return 1-based rank
      }
      
      return null;
    } catch (e) {
      debugPrint('[RankService] fetchCurrentUserRank error: $e');
      return null;
    }
  }
}

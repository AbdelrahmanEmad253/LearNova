import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RankService {
  final SupabaseClient _client;

  const RankService(this._client);

  Future<List<Map<String, dynamic>>> fetchLeaderboard(String track) async {
    try {
      final response = await _client.rpc(
        'get_leaderboard_data',
        params: {
          'target_track': track,
        },
      );
          
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
      // First get the user's track
      final profileRes = await _client
          .from('student_profiles')
          .select('assigned_track')
          .eq('id', user.id)
          .maybeSingle();
      final track = profileRes?['assigned_track'] ?? 'Foundation';

      // Find the user's position in the top 100 leaderboard
      final leaderboard = await fetchLeaderboard(track);
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

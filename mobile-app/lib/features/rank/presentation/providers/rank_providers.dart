import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/services/supabase/rank_service.dart';
import 'package:learnova/features/rank/domain/entities/rank_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final rankServiceProvider = Provider<RankService>((ref) {
  return RankService(ref.watch(supabaseClientProvider));
});

String _getRankName(int xp) {
  if (xp < 100) return 'Novice Explorer';
  if (xp < 500) return 'Curious Learner';
  if (xp < 1000) return 'Dedicated Student';
  if (xp < 2000) return 'Knowledge Seeker';
  if (xp < 5000) return 'Academic Scholar';
  return 'Master of Wisdom';
}

class RankController extends AsyncNotifier<RankData> {
  @override
  FutureOr<RankData> build() async {
    return _fetchData();
  }

  Future<RankData> _fetchData() async {
    final service = ref.read(rankServiceProvider);
    final leaderboardRaw = await service.fetchLeaderboard();
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    int currentUserPos = 0;
    int currentUserXp = 0;

    final List<RankEntry> leaderboard = [];
    
    for (int i = 0; i < leaderboardRaw.length; i++) {
      final row = leaderboardRaw[i];
      final isMe = row['user_id'] == currentUserId;
      final xp = (row['xp_total'] as int?) ?? 0;
      final userDict = row['users'] as Map<String, dynamic>?;
      
      if (isMe) {
        currentUserPos = i + 1;
        currentUserXp = xp;
      }

      leaderboard.add(
        RankEntry(
          id: row['user_id'].toString(),
          name: userDict?['full_name']?.toString() ?? 'User',
          userTag: '#${row['user_id'].toString().substring(0, 6)}',
          position: i + 1,
          pointsChange: 0, // Defaulting to 0 since we have no history table
          avatarUrl: userDict?['avatar_url']?.toString(),
          isCurrentUser: isMe,
        )
      );
    }

    // Default if not found
    if (currentUserPos == 0 && currentUserId != null) {
        currentUserPos = leaderboard.length + 1; 
    }

    final currentRankName = _getRankName(currentUserXp);
    final nextRankName = _getRankName(currentUserXp + 1000); // placeholder next
    final remainingXP = 1000 - (currentUserXp % 1000); // placeholder math
    final xpProgress = (currentUserXp % 1000) / 1000.0;

    return RankData(
      screenTitle: 'Leaderboard',
      currentUserPosition: currentUserPos,
      currentRankName: currentRankName,
      nextRankName: nextRankName,
      remainingXP: remainingXP,
      xpProgress: xpProgress,
      leaderboard: leaderboard,
    );
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}

final rankDataProvider = AsyncNotifierProvider<RankController, RankData>(() {
  return RankController();
});

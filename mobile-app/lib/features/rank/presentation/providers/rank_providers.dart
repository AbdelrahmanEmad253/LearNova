import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/services/supabase/rank_service.dart';
import 'package:learnova/features/rank/domain/entities/rank_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

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
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    // Watch student profile so rank updates when XP changes
    final studentProfile = ref.watch(studentProfileProvider).value;
    final track = studentProfile?.assignedTrack ?? 'Foundation';

    final service = ref.read(rankServiceProvider);
    final leaderboardRaw = await service.fetchLeaderboard(track);

    int currentUserPos = 0;
    int currentUserXp = studentProfile?.totalXp ?? 0;

    final List<RankEntry> leaderboard = [];
    
    for (int i = 0; i < leaderboardRaw.length; i++) {
      final row = leaderboardRaw[i];
      final isMe = row['user_id'] == currentUserId;
      final xp = (row['xp_at_snapshot'] as int?) ?? 0;
      final rank = (row['rank_at_snapshot'] as int?) ?? (i + 1);
      if (isMe) {
        currentUserPos = rank;
        currentUserXp = xp;
      }

      leaderboard.add(
        RankEntry(
          id: row['user_id'].toString(),
          name: row['full_name']?.toString() ?? 'User',
          userTag: '#${row['user_id'].toString().substring(0, 6)}',
          position: rank,
          xp: xp,
          avatarUrl: row['avatar_url']?.toString(),
          isCurrentUser: isMe,
        )
      );
    }

    // Default if not found
    if (currentUserPos == 0 && currentUserId != null) {
        currentUserPos = leaderboard.length + 1; 
    }

    final currentRankName = _getRankName(currentUserXp);
    
    int nextRankThreshold = 5000;
    if (currentUserXp < 100) nextRankThreshold = 100;
    else if (currentUserXp < 500) nextRankThreshold = 500;
    else if (currentUserXp < 1000) nextRankThreshold = 1000;
    else if (currentUserXp < 2000) nextRankThreshold = 2000;
    else if (currentUserXp < 5000) nextRankThreshold = 5000;
    else nextRankThreshold = currentUserXp; // Max rank reached
    
    int currentRankBase = 0;
    if (currentUserXp >= 100 && currentUserXp < 500) currentRankBase = 100;
    else if (currentUserXp >= 500 && currentUserXp < 1000) currentRankBase = 500;
    else if (currentUserXp >= 1000 && currentUserXp < 2000) currentRankBase = 1000;
    else if (currentUserXp >= 2000 && currentUserXp < 5000) currentRankBase = 2000;
    else if (currentUserXp >= 5000) currentRankBase = 5000;

    final nextRankName = currentUserXp >= 5000 ? 'Max Rank' : _getRankName(nextRankThreshold);
    final remainingXP = currentUserXp >= 5000 ? 0 : nextRankThreshold - currentUserXp;
    
    double xpProgress = 1.0;
    if (currentUserXp < 5000) {
      xpProgress = (currentUserXp - currentRankBase) / (nextRankThreshold - currentRankBase);
    }

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

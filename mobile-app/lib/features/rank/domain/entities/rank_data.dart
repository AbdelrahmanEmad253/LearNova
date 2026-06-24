class RankData {
  final String screenTitle;
  final int currentUserPosition;
  final String currentRankName;
  final String nextRankName;
  final int remainingXP;
  final double xpProgress;
  final List<RankEntry> leaderboard;

  const RankData({
    required this.screenTitle,
    required this.currentUserPosition,
    required this.currentRankName,
    required this.nextRankName,
    required this.remainingXP,
    required this.xpProgress,
    required this.leaderboard,
  });
}

class RankEntry {
  final String id;
  final String name;
  final String userTag;
  final int position;
  final int xp;
  final String? avatarUrl;
  final bool isCurrentUser;

  const RankEntry({
    required this.id,
    required this.name,
    required this.userTag,
    required this.position,
    required this.xp,
    this.avatarUrl,
    this.isCurrentUser = false,
  });
}

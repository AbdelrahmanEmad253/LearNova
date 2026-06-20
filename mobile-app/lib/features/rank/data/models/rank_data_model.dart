import 'package:learnova/features/rank/domain/entities/rank_data.dart';

class RankDataModel {
  final String screenTitle;
  final int currentUserPosition;
  final String currentRankName;
  final String nextRankName;
  final int remainingXP;
  final double xpProgress;
  final List<RankEntryModel> leaderboard;

  const RankDataModel({
    required this.screenTitle,
    required this.currentUserPosition,
    required this.currentRankName,
    required this.nextRankName,
    required this.remainingXP,
    required this.xpProgress,
    required this.leaderboard,
  });

  RankData toEntity() {
    return RankData(
      screenTitle: screenTitle,
      currentUserPosition: currentUserPosition,
      currentRankName: currentRankName,
      nextRankName: nextRankName,
      remainingXP: remainingXP,
      xpProgress: xpProgress,
      leaderboard: leaderboard.map((entry) => entry.toEntity()).toList(),
    );
  }
}

class RankEntryModel {
  final String id;
  final String name;
  final String userTag;
  final int position;
  final int pointsChange;
  final String? avatarUrl;
  final bool isCurrentUser;

  const RankEntryModel({
    required this.id,
    required this.name,
    required this.userTag,
    required this.position,
    required this.pointsChange,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  RankEntry toEntity() {
    return RankEntry(
      id: id,
      name: name,
      userTag: userTag,
      position: position,
      pointsChange: pointsChange,
      avatarUrl: avatarUrl,
      isCurrentUser: isCurrentUser,
    );
  }
}

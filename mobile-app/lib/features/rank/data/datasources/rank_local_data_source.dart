import 'package:learnova/features/rank/data/models/rank_data_model.dart';
import 'package:learnova/core/constants/app_assets.dart';

class RankLocalDataSource {
  const RankLocalDataSource();

  Future<RankDataModel> getRankData() async {
    // Simulate network delay for Riverpod loading states
    await Future.delayed(const Duration(milliseconds: 1200));

    return const RankDataModel(
      screenTitle: 'Leaderboard',
      currentUserPosition: 28,
      currentRankName: 'Novice',
      nextRankName: '???',
      remainingXP: 582,
      xpProgress: 0.35,
      leaderboard: [
        RankEntryModel(
          id: '1',
          name: 'Sarah Chen',
          userTag: '#111111',
          position: 1,
          pointsChange: 12,
        ),
        RankEntryModel(
          id: '2',
          name: 'Alex Rivera',
          userTag: '#222222',
          position: 2,
          pointsChange: -3,
        ),
        RankEntryModel(
          id: '3',
          name: 'Priya Patel',
          userTag: '#333333',
          position: 3,
          pointsChange: 5,
        ),
        RankEntryModel(
          id: '4',
          name: 'Jordan Lee',
          userTag: '#444444',
          position: 4,
          pointsChange: 0,
        ),
        RankEntryModel(
          id: '5',
          name: 'Sam Taylor',
          userTag: '#555555',
          position: 5,
          pointsChange: 2,
        ),
        RankEntryModel(
          id: '27',
          name: 'Amelia Earhart',
          userTag: '#777777',
          position: 27,
          pointsChange: -2,
        ),
        RankEntryModel(
          id: '28',
          name: 'You',
          userTag: '#234451',
          position: 28,
          pointsChange: 4,
          isCurrentUser: true,
        ),
        RankEntryModel(
          id: '29',
          name: 'Marco Polo',
          userTag: '#999999',
          position: 29,
          pointsChange: 1,
        ),
      ],
    );
  }
}

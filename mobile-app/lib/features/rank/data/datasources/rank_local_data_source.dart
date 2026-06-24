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
          name: 'Ahmed Yasser',
          userTag: '#ay123',
          position: 1,
          xp: 12000,
          avatarUrl: 'https://i.pravatar.cc/150?img=11',
          isCurrentUser: true,
        ),
        RankEntryModel(
          id: '2',
          name: 'Adham Wahba',
          userTag: '#aw456',
          position: 2,
          xp: 11500,
          avatarUrl: 'https://i.pravatar.cc/150?img=12',
        ),
        RankEntryModel(
          id: '3',
          name: 'Tester 4',
          userTag: '#tst004',
          position: 3,
          xp: 10800,
          avatarUrl: 'https://i.pravatar.cc/150?img=5',
        ),
        RankEntryModel(
          id: '4',
          name: 'Tester',
          userTag: '#tst001',
          position: 4,
          xp: 9400,
          avatarUrl: 'https://i.pravatar.cc/150?img=8',
        ),
        RankEntryModel(
          id: '5',
          name: 'Learno',
          userTag: '#lrno99',
          position: 5,
          xp: 8900,
          avatarUrl: 'https://i.pravatar.cc/150?img=14',
        ),
        RankEntryModel(
          id: '6',
          name: 'Omar Sherif',
          userTag: '#osherf',
          position: 6,
          xp: 8200,
        ),
        RankEntryModel(
          id: '7',
          name: 'John Doe',
          userTag: '#jdoe',
          position: 7,
          xp: 7500,
        ),
        RankEntryModel(
          id: '8',
          name: 'Sarah Smith',
          userTag: '#ssmith',
          position: 8,
          xp: 6800,
        ),
      ],
    );
  }
}

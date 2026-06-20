import 'package:learnova/features/profile/data/models/profile_data_model.dart';
import 'package:learnova/core/constants/app_assets.dart';

class ProfileLocalDataSource {
  const ProfileLocalDataSource();

  ProfileDataModel getProfileData() {
    return const ProfileDataModel(
      username: 'Honda@847',
      rank: 'Novice',
      journeyCompletion: 0.12,
      timeStatus: [
        TimeStatusPointModel(label: 'Per Level', value: 2.0),
        TimeStatusPointModel(label: 'Current Week', value: 6.7),
        TimeStatusPointModel(label: 'Current Month', value: 6.7),
        TimeStatusPointModel(label: 'Total Time', value: 14.0),
      ],
      infoItems: [
        ProfileInfoItemModel(label: 'Rank', value: '#928523'),
        ProfileInfoItemModel(label: 'Track', value: 'Data Scientist'),
        ProfileInfoItemModel(label: 'Achievements', value: '1'),
      ],
      weeklyActivity: [true, true, true, true, true, false, false],
      perks: [
        PerkItemModel(
          imagePath: AppAssets.profileSliFox,
          name: 'Sli-Fox RX50',
          subtitle: 'Grants you a hint once',
        ),
        PerkItemModel(name: '???', subtitle: '?????'),
        PerkItemModel(name: '???', subtitle: '?????'),
      ],
      badges: [
        BadgeItemModel(label: 'Amateur Brain', isLocked: false),
        BadgeItemModel(label: '???', isLocked: true),
        BadgeItemModel(label: 'Perfect Score', isLocked: true),
      ],
      activeStreak: 14,
    );
  }
}

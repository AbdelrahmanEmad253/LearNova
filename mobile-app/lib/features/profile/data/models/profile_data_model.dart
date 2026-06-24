import 'package:learnova/features/profile/domain/entities/profile_data.dart';

class ProfileDataModel {
  final String username;
  final String rank;
  final int totalXp;
  final double xpProgress;
  final double journeyCompletion;
  final List<TimeStatusPointModel> timeStatus;
  final List<ProfileInfoItemModel> infoItems;
  final List<bool> weeklyActivity;
  final List<PerkItemModel> perks;
  final List<BadgeItemModel> badges;
  final int activeStreak;
  final String? avatarUrl;

  const ProfileDataModel({
    required this.username,
    required this.rank,
    required this.totalXp,
    required this.xpProgress,
    required this.journeyCompletion,
    required this.timeStatus,
    required this.infoItems,
    required this.weeklyActivity,
    required this.perks,
    required this.badges,
    required this.activeStreak,
    this.avatarUrl,
  });

  ProfileData toEntity() {
    return ProfileData(
      username: username,
      rank: rank,
      totalXp: totalXp,
      xpProgress: xpProgress,
      journeyCompletion: journeyCompletion,
      timeStatus: timeStatus.map((item) => item.toEntity()).toList(),
      infoItems: infoItems.map((item) => item.toEntity()).toList(),
      weeklyActivity: weeklyActivity,
      perks: perks.map((item) => item.toEntity()).toList(),
      badges: badges.map((item) => item.toEntity()).toList(),
      activeStreak: activeStreak,
      avatarUrl: avatarUrl,
    );
  }
}

class TimeStatusPointModel {
  final String label;
  final double value;

  const TimeStatusPointModel({required this.label, required this.value});

  TimeStatusPoint toEntity() {
    return TimeStatusPoint(label: label, value: value);
  }
}

class ProfileInfoItemModel {
  final String label;
  final String value;

  const ProfileInfoItemModel({required this.label, required this.value});

  ProfileInfoItem toEntity() {
    return ProfileInfoItem(label: label, value: value);
  }
}

class PerkItemModel {
  final String name;
  final int count;
  final String? imagePath;

  const PerkItemModel(
      {required this.name, required this.count, this.imagePath});

  PerkItem toEntity() {
    return PerkItem(name: name, count: count, imagePath: imagePath);
  }
}

class BadgeItemModel {
  final String label;
  final bool isLocked;
  final String? imageUrl;

  const BadgeItemModel({required this.label, required this.isLocked, this.imageUrl});

  BadgeItem toEntity() {
    return BadgeItem(label: label, isLocked: isLocked, imageUrl: imageUrl);
  }
}


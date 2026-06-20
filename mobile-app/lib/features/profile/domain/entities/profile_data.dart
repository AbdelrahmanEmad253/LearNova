class ProfileData {
  final String username;
  final String? avatarUrl;
  final String rank;
  final double journeyCompletion;
  final List<TimeStatusPoint> timeStatus;
  final List<ProfileInfoItem> infoItems;
  final List<bool> weeklyActivity;
  final List<PerkItem> perks;
  final List<BadgeItem> badges;
  final int activeStreak;

  const ProfileData({
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.journeyCompletion,
    required this.timeStatus,
    required this.infoItems,
    required this.weeklyActivity,
    required this.perks,
    required this.badges,
    required this.activeStreak,
  });
}

class TimeStatusPoint {
  final String label;
  final double value;

  const TimeStatusPoint({required this.label, required this.value});
}

class ProfileInfoItem {
  final String label;
  final String value;

  const ProfileInfoItem({required this.label, required this.value});
}

class PerkItem {
  final String name;
  final String subtitle;
  final String? imagePath;

  const PerkItem({required this.name, required this.subtitle, this.imagePath});
}

class BadgeItem {
  final String label;
  final bool isLocked;

  const BadgeItem({required this.label, required this.isLocked});
}


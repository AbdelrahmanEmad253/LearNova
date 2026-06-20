import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/services/supabase/user_data_service.dart';
import 'package:learnova/core/services/supabase/activity_tracking_service.dart';
import 'package:learnova/core/services/supabase/achievements_service.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/features/profile/domain/entities/profile_data.dart';

// Services
final profileUserDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService(ref.watch(supabaseClientProvider));
});

final profileActivityServiceProvider = Provider<ActivityTrackingService>((ref) {
  return ActivityTrackingService(ref.watch(supabaseClientProvider));
});

final profileAchievementsServiceProvider = Provider<AchievementsService>((ref) {
  return AchievementsService(ref.watch(supabaseClientProvider));
});

// Calculate rank from XP
String _getRankName(int xp) {
  if (xp < 100) return 'Novice Explorer';
  if (xp < 500) return 'Curious Learner';
  if (xp < 1000) return 'Dedicated Student';
  if (xp < 2000) return 'Knowledge Seeker';
  if (xp < 5000) return 'Academic Scholar';
  return 'Master of Wisdom';
}

final profileDataProvider = FutureProvider<ProfileData>((ref) async {
  final userDataService = ref.watch(profileUserDataServiceProvider);
  final activityService = ref.watch(profileActivityServiceProvider);
  final achievementsService = ref.watch(profileAchievementsServiceProvider);
  final studentProfileAsync = ref.watch(studentProfileProvider);

  // Default values if data fails to load
  String username = 'User';
  String? avatarUrl;
  String rank = 'Novice Explorer';
  double journeyCompletion = 0.0;
  List<TimeStatusPoint> timeStatus = [];
  List<ProfileInfoItem> infoItems = [];
  List<bool> weeklyActivity = List.filled(7, false);

  // 1. Fetch user data (full_name, avatar_url)
  final userData = await userDataService.fetchCurrentUser();
  if (userData != null) {
    username = userData['full_name']?.toString() ?? userData['email']?.toString().split('@').first ?? 'User';
    avatarUrl = userData['avatar_url']?.toString();
  }

  // 2. Fetch student profile data (xp, track, level)
  final studentProfile = studentProfileAsync.value;
  if (studentProfile != null) {
    rank = _getRankName(studentProfile.totalXp);
    
    // We don't have current_level_index in StudentProfile entity yet, defaulting to 0 for completion
    journeyCompletion = 0.0; 

    // Info items
    infoItems = [
      ProfileInfoItem(label: 'Rank', value: rank),
      ProfileInfoItem(label: 'Track', value: studentProfile.zoneState ?? 'None'),
      ProfileInfoItem(label: 'Achievements', value: '${studentProfile.momentumStreak}'),
    ];
  } else {
    infoItems = [
      ProfileInfoItem(label: 'Rank', value: rank),
      ProfileInfoItem(label: 'Track', value: 'Not Assigned'),
      ProfileInfoItem(label: 'Achievements', value: '0'),
    ];
  }

  // 3. Fetch activity tracking data (concurrently)
  final trackingResults = await Future.wait([
    activityService.getAverageTimePerLevel(),
    activityService.getWeeklyTime(),
    activityService.getMonthlyTime(),
    activityService.getTotalTime(),
    activityService.getWeeklyActivity(),
    activityService.getActiveWeekStreak(),
  ]);

  timeStatus = [
    TimeStatusPoint(label: 'Per Level', value: trackingResults[0] as double),
    TimeStatusPoint(label: 'Current Week', value: trackingResults[1] as double),
    TimeStatusPoint(label: 'Current Month', value: trackingResults[2] as double),
    TimeStatusPoint(label: 'Total Time', value: trackingResults[3] as double),
  ];

  weeklyActivity = trackingResults[4] as List<bool>;
  final activeStreak = trackingResults[5] as int;

  // Static perks for now
  final perks = [
    const PerkItem(name: 'Ad-free Experience', subtitle: 'Focus without interruptions'),
    const PerkItem(name: 'Exclusive Content', subtitle: 'Access to premium materials'),
  ];

  // Fetch real achievements
  final userAchievementsRaw = await achievementsService.fetchUserAchievements();
  final badges = userAchievementsRaw.map((a) {
    final dict = a['achievements_dictionary'] as Map<String, dynamic>?;
    return BadgeItem(
      label: dict?['label']?.toString() ?? 'Achievement', 
      isLocked: false
    );
  }).toList();
  
  if (badges.isEmpty) {
    badges.add(const BadgeItem(label: 'Complete a module to earn a badge!', isLocked: true));
  }

  // Update achievements info item if loaded
  if (studentProfile != null) {
    infoItems[2] = ProfileInfoItem(label: 'Achievements', value: '${badges.where((b) => !b.isLocked).length}');
  }

  return ProfileData(
    username: username,
    avatarUrl: avatarUrl,
    rank: rank,
    journeyCompletion: journeyCompletion,
    timeStatus: timeStatus,
    infoItems: infoItems,
    weeklyActivity: weeklyActivity,
    perks: perks,
    badges: badges,
    activeStreak: activeStreak,
  );
});

// A provider for saving changes
class ProfileEditsNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> saveUsername(String newUsername) async {
    final service = ref.read(profileUserDataServiceProvider);
    await service.updateFullName(newUsername);
    // Refresh the profile data
    ref.invalidate(profileDataProvider);
  }
}

final profileEditsNotifierProvider = NotifierProvider<ProfileEditsNotifier, void>(ProfileEditsNotifier.new);

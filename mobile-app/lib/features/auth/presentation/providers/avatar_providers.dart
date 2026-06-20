import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/services/supabase/user_data_service.dart';
import 'package:learnova/core/services/supabase/activity_tracking_service.dart';

// ── Service Providers ──

final userDataServiceProvider = Provider<UserDataService>((ref) {
  return UserDataService(ref.watch(supabaseClientProvider));
});

final activityTrackingServiceProvider = Provider<ActivityTrackingService>((ref) {
  return ActivityTrackingService(ref.watch(supabaseClientProvider));
});

// ── User Data Providers ──

/// Current user's data from the public.users table.
final currentUserDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.watch(userDataServiceProvider);
  return service.fetchCurrentUser();
});

/// Current user's full_name from users table.
final currentUsernameProvider = Provider<String>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (data) => data?['full_name']?.toString() ?? data?['email']?.toString().split('@').first ?? 'User',
    loading: () => '...',
    error: (_, __) => 'User',
  );
});

/// Current user's avatar URL from users table.
final currentAvatarUrlProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (data) => data?['avatar_url']?.toString(),
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── Activity Tracking Providers ──

final timeStatusProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(activityTrackingServiceProvider);
  final results = await Future.wait([
    service.getAverageTimePerLevel(),
    service.getWeeklyTime(),
    service.getMonthlyTime(),
    service.getTotalTime(),
  ]);
  return {
    'Per Level': results[0],
    'Current Week': results[1],
    'Current Month': results[2],
    'Total Time': results[3],
  };
});

final weeklyActivityProvider = FutureProvider<List<bool>>((ref) async {
  final service = ref.watch(activityTrackingServiceProvider);
  return service.getWeeklyActivity();
});

final activeWeekStreakProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(activityTrackingServiceProvider);
  return service.getActiveWeekStreak();
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/services/notifications/local_notification_service.dart';
import 'package:learnova/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:learnova/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:learnova/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:learnova/features/profile/domain/repositories/profile_repository.dart';

// Providers for Profile Domain
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(ref.watch(supabaseClientProvider));
});

final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>((ref) {
  return ProfileLocalDataSource();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    localDataSource: ref.watch(profileLocalDataSourceProvider),
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
  );
});

// Notifier State
class ReminderSettingsState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final TimeOfDay? time;
  final bool isEmail;
  final bool isPush;

  const ReminderSettingsState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.time,
    this.isEmail = false,
    this.isPush = false,
  });

  ReminderSettingsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    TimeOfDay? time,
    bool? isEmail,
    bool? isPush,
  }) {
    return ReminderSettingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      time: time ?? this.time,
      isEmail: isEmail ?? this.isEmail,
      isPush: isPush ?? this.isPush,
    );
  }
}

// State Notifier
class ReminderSettingsNotifier extends Notifier<ReminderSettingsState> {
  @override
  ReminderSettingsState build() {
    _loadSettings();
    return const ReminderSettingsState(isLoading: true);
  }

  Future<void> _loadSettings() async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      final data = await repository.getReminderSettings();
      if (data != null) {
        final String timeStr = data['reminder_time'] as String;
        final parts = timeStr.split(':');
        final timeOfDay = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        state = state.copyWith(
          isLoading: false,
          time: timeOfDay,
          isEmail: data['is_email_enabled'] as bool? ?? false,
          isPush: data['is_push_enabled'] as bool? ?? false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> saveReminderSettings({
    required TimeOfDay time,
    required bool isEmail,
    required bool isPush,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      // Format time as HH:mm:ss
      final String formattedTime =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

      // 1. Save to Supabase
      final repository = ref.read(profileRepositoryProvider);
      await repository.upsertReminderSettings(
        time: formattedTime,
        isEmail: isEmail,
        isPush: isPush,
      );

      // 2. Schedule or Cancel local notifications
      if (isPush) {
        await LocalNotificationService.scheduleDailyReminder(time);
      } else {
        await LocalNotificationService.cancelDailyReminder();
      }

      state = state.copyWith(
        isLoading: false, 
        isSuccess: true,
        time: time,
        isEmail: isEmail,
        isPush: isPush,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final reminderSettingsNotifierProvider =
    NotifierProvider<ReminderSettingsNotifier, ReminderSettingsState>(() {
  return ReminderSettingsNotifier();
});

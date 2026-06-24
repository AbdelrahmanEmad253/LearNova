import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/notifications/data/models/notifications_data_model.dart';
import 'package:learnova/features/notifications/presentation/providers/notifications_providers.dart';

class LocalNotificationService {
  static const String channelKey = 'reminder_channel';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // default icon (from android/app/src/main/res/drawable)
      [
        NotificationChannel(
          channelGroupKey: 'reminder_channel_group',
          channelKey: channelKey,
          channelName: 'Study Reminders',
          channelDescription: 'Notification channel for daily study reminders',
          defaultColor: const Color(0xFF1D5594),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'reminder_channel_group',
          channelGroupName: 'Reminders Group',
        )
      ],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: LocalNotificationService.onActionReceivedMethod,
      onNotificationDisplayedMethod: LocalNotificationService.onNotificationDisplayedMethod,
    );
  }

  static Future<void> checkMissedReminders(ProviderContainer container) async {
    final prefs = await SharedPreferences.getInstance();
    final lastDisplayed = prefs.getInt('last_reminder_displayed_time');
    final lastProcessed = prefs.getInt('last_reminder_processed_time') ?? 0;

    if (lastDisplayed != null && lastDisplayed > lastProcessed) {
      container.read(notificationsDataProvider.notifier).addNotification(
        NotificationItemModel(
          id: 'reminder_$lastDisplayed',
          title: 'Time to level up! 📚',
          description: 'The floating islands are waiting. Jump into the maze and boost your XP now! 🚀',
          createdAt: lastDisplayed,
          deeplink: 'map',
          isUnread: true,
        ),
      );
      await prefs.setInt('last_reminder_processed_time', lastDisplayed);
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    if (receivedNotification.channelKey == channelKey) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_reminder_displayed_time', DateTime.now().millisecondsSinceEpoch);
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Optional: we can handle direct routing here if we want, but since they will 
    // click the OS notification, the app will open and it will be in the notification screen.
  }

  static Future<bool> requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    final isAllowed = await requestPermissions();
    if (!isAllowed) return;

    // Use a fixed ID for the daily reminder so it overrides any existing one
    const int notificationId = 1001;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        title: 'Time to level up! 📚',
        body: 'The floating islands are waiting. Jump into the maze and boost your XP now! 🚀',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Daily repeat
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> cancelDailyReminder() async {
    const int notificationId = 1001;
    await AwesomeNotifications().cancel(notificationId);
  }
}

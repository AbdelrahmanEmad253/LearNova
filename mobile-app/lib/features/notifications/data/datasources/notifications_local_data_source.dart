import 'package:learnova/features/notifications/data/models/notifications_data_model.dart';

class NotificationsLocalDataSource {
  const NotificationsLocalDataSource();

  NotificationsDataModel getNotificationsData() {
    return const NotificationsDataModel(
      screenTitle: 'Notifications',
      headline: 'Stay updated',
      subtitle: 'Your latest progress, rewards, and reminders all in one place.',
      items: [
        NotificationItemModel(
          id: 'reward_1',
          title: 'Quest reward ready',
          description: 'You completed enough quests to open your weekly chest.',
          timeLabel: '5 min ago',
          isUnread: true,
        ),
        NotificationItemModel(
          id: 'assessment_1',
          title: 'Assessment unlocked',
          description: 'A new beginner assessment is now available on your map.',
          timeLabel: '1 hr ago',
          isUnread: true,
        ),
        NotificationItemModel(
          id: 'streak_1',
          title: 'Streak reminder',
          description: 'Log in today to keep your 2-week streak active.',
          timeLabel: 'Today',
        ),
        NotificationItemModel(
          id: 'rank_1',
          title: 'Leaderboard update',
          description: 'You climbed 12 places in the weekly ranking.',
          timeLabel: 'Yesterday',
        ),
      ],
    );
  }
}


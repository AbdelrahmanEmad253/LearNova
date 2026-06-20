class NotificationsData {
  final String screenTitle;
  final String headline;
  final String subtitle;
  final List<NotificationItem> items;

  const NotificationsData({
    required this.screenTitle,
    required this.headline,
    required this.subtitle,
    required this.items,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String timeLabel;
  final bool isUnread;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLabel,
    this.isUnread = false,
  });
}


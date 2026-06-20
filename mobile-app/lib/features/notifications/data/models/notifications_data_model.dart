import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';

class NotificationsDataModel {
  final String screenTitle;
  final String headline;
  final String subtitle;
  final List<NotificationItemModel> items;

  const NotificationsDataModel({
    required this.screenTitle,
    required this.headline,
    required this.subtitle,
    required this.items,
  });

  NotificationsData toEntity() {
    return NotificationsData(
      screenTitle: screenTitle,
      headline: headline,
      subtitle: subtitle,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

class NotificationItemModel {
  final String id;
  final String title;
  final String description;
  final String timeLabel;
  final bool isUnread;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timeLabel,
    this.isUnread = false,
  });

  NotificationItem toEntity() {
    return NotificationItem(
      id: id,
      title: title,
      description: description,
      timeLabel: timeLabel,
      isUnread: isUnread,
    );
  }
}


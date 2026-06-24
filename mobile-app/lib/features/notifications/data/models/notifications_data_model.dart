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

  factory NotificationsDataModel.fromJson(Map<String, dynamic> json) {
    return NotificationsDataModel(
      screenTitle: json['screenTitle'] ?? 'Notifications',
      headline: json['headline'] ?? 'Stay updated',
      subtitle: json['subtitle'] ?? 'Your latest progress, rewards, and reminders all in one place.',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screenTitle': screenTitle,
      'headline': headline,
      'subtitle': subtitle,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class NotificationItemModel {
  final String id;
  final String title;
  final String description;
  final int createdAt;
  final String? deeplink;
  final bool isUnread;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.deeplink,
    this.isUnread = false,
  });

  NotificationItem toEntity() {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final difference = now.difference(date);
    
    String timeLabel;
    if (difference.inDays > 1) {
      timeLabel = '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      timeLabel = '1 day ago';
    } else if (difference.inHours > 0) {
      timeLabel = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeLabel = '${difference.inMinutes} min ago';
    } else {
      timeLabel = 'Just now';
    }

    return NotificationItem(
      id: id,
      title: title,
      description: description,
      timeLabel: timeLabel,
      deeplink: deeplink,
      isUnread: isUnread,
    );
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      deeplink: json['deeplink'] as String?,
      isUnread: json['isUnread'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt,
      'deeplink': deeplink,
      'isUnread': isUnread,
    };
  }
}


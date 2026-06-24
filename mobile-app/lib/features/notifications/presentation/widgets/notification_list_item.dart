import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/features/notifications/presentation/screens/notifications_screen.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/notifications/presentation/providers/notifications_providers.dart';

class NotificationListItem extends ConsumerWidget {
  const NotificationListItem({super.key, required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (item.isUnread) {
          ref.read(notificationsDataProvider.notifier).markAsRead(item.id);
        }

        final dl = item.deeplink?.toLowerCase() ?? '';
        if (dl.contains('leaderboard')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 3)));
        } else if (dl.contains('notifications')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        } else if (dl.contains('map')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)));
        } else if (dl.contains('challenge') || dl.contains('daily')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 1)));
        } else if (dl.contains('chat') || dl.contains('mitchy')) {
          final contentStr = item.description;
          if (contentStr.isNotEmpty) {
            // No need to inject message manually; the chat screen will fetch the latest 
            // session history from the database which already contains this message.
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 2)));
        } else if (dl.contains('profile')) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 4)));
        } else {
          // Fallback if no deeplink or unrecognized
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen(initialIndex: 0)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ColorManager.uiBlueDeep.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorManager.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: ColorManager.overlayBlackSoft,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.isUnread
                  ? ColorManager.primary.withValues(alpha: 0.18)
                  : ColorManager.textSecondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isUnread ? Icons.notifications_active_outlined : Icons.notifications_none,
              color: item.isUnread ? ColorManager.primary : ColorManager.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: ColorManager.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: item.isUnread ? ColorManager.primary : ColorManager.textSecondary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.timeLabel,
                  style: const TextStyle(
                    color: ColorManager.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}


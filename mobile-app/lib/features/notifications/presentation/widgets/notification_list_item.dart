import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';

class NotificationListItem extends StatelessWidget {
  const NotificationListItem({super.key, required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  : ColorManager.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isUnread ? Icons.notifications_active_outlined : Icons.notifications_none,
              color: item.isUnread ? ColorManager.primary : ColorManager.white,
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
                    if (item.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ColorManager.primary,
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
    );
  }
}


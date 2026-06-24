import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/notifications/domain/entities/notifications_data.dart';
import 'package:learnova/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:learnova/features/notifications/presentation/widgets/notification_list_item.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size size = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;
    final NotificationsData data = ref.watch(notificationsDataProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Background
          const Positioned.fill(
            child: AppBackground(),
          ),

          // 2. Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topPadding),
                  SvgPicture.asset(
                    AppAssets.mapScrollTop,
                    width: size.width,
                    fit: BoxFit.fitWidth,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.headline,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data.subtitle,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ...List.generate(data.items.length, (index) {
                          final item = data.items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: index == data.items.length - 1 ? 0 : 16),
                            child: Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) {
                                ref.read(notificationsDataProvider.notifier).removeNotification(item.id);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                              ),
                              child: NotificationListItem(item: item),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fixed top SVG overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapFixedTop,
                width: size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          // 4. Back arrow + title header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, topPadding + 10, 24, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back,
                      color: colors.textPrimary,
                      size: 26,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data.screenTitle,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/features/notifications/presentation/screens/notifications_screen.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../theme/app_colors.dart';

import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/profile/presentation/providers/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTopBar extends ConsumerWidget {
  final double topPadding;
  final String title;
  final String? rankName;
  final double? progress;

  const AppTopBar({
    super.key,
    required this.topPadding,
    this.title = 'Levels',
    this.rankName,
    this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    
    // If rankName/progress aren't explicitly passed (or are null), fetch them from student profile
    final studentProfileAsync = ref.watch(studentProfileProvider);
    final profile = studentProfileAsync.value;
    
    // Convert totalXp to rank and progress using the same logic as profile/rank
    final xp = profile?.totalXp ?? 0;
    
    // Simple helper to get rank name from XP if not provided
    String getRankName(int xp) {
      if (xp < 100) return 'Novice Explorer';
      if (xp < 500) return 'Curious Learner';
      if (xp < 1000) return 'Dedicated Student';
      if (xp < 2000) return 'Knowledge Seeker';
      if (xp < 5000) return 'Academic Scholar';
      return 'Master of Wisdom';
    }

    double getXpProgress(int xp) {
      if (xp < 100) return xp / 100.0;
      if (xp < 500) return (xp - 100) / (500 - 100);
      if (xp < 1000) return (xp - 500) / (1000 - 500);
      if (xp < 2000) return (xp - 1000) / (2000 - 1000);
      if (xp < 5000) return (xp - 2000) / (5000 - 2000);
      return 1.0;
    }
    
    final displayRankName = rankName ?? getRankName(xp);
    final displayProgress = progress ?? getXpProgress(xp);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 10, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left — Rank & progress
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.starIcon,
                        width: 18,
                        colorFilter:
                            const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          displayRankName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildProgressBar(colors, displayProgress),
                ],
              ),
            ),
          ),

          // Center — Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Right — Notification bell
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  AppRouter.push(context, const NotificationsScreen());
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.cardBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderWeak, width: 1),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AppColors colors, double progressVal) {
    return Container(
      width: 100,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progressVal.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: ColorManager.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

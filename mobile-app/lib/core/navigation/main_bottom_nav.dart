import 'package:flutter/material.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/constants/app_durations.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';

class MainBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const MainBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: colors.borderWeak),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIconTab(colors, 0, Icons.home_outlined),
          _buildIconTab(colors, 1, Icons.map_outlined),
          _buildMitchyTab(colors, 2),
          _buildIconTab(colors, 3, Icons.leaderboard_outlined),
          _buildIconTab(colors, 4, Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildIconTab(AppColors colors, int index, IconData icon) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : ColorManager.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.primary : colors.textSecondary,
          size: isSelected ? 30 : 28,
        ),
      ),
    );
  }

  Widget _buildMitchyTab(AppColors colors, int index) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? colors.primary : colors.borderSoft,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: Image.asset(
            AppAssets.avatarMitchy,
            width: isSelected ? 38 : 34,
            height: isSelected ? 38 : 34,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

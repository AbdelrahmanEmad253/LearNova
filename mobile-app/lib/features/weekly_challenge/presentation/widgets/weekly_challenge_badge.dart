import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';

class WeeklyChallengeBadge extends StatelessWidget {
  const WeeklyChallengeBadge({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 16),
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ColorManager.badgeBorder, width: 2),
          boxShadow: const [
            BoxShadow(
              color: ColorManager.overlayBlackMild,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: ColorManager.uiBlue600,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

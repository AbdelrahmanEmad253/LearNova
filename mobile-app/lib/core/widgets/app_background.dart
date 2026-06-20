import 'package:flutter/material.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';

/// A reusable background widget that renders:
/// - Dark mode: the space background image
/// - Light mode: a vertical linear gradient (#FAFBFD → #C7D6E6)
///
/// Usage: Place as a `Positioned.fill` child inside a `Stack`.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    if (colors.isDark) {
      return Image.asset(AppAssets.spaceBackground, fit: BoxFit.cover);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ColorManager.lightGradientStart,
            ColorManager.lightGradientEnd,
          ],
        ),
      ),
    );
  }
}

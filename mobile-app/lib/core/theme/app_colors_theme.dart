import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';

class AppColors {
  final bool isDark;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color backgroundSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTitle;
  final Color cardBackground;
  final Color borderWeak;
  final Color borderSoft;
  final Color buttonBackground;
  final Color buttonForeground;

  const AppColors({
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.backgroundSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTitle,
    required this.cardBackground,
    required this.borderWeak,
    required this.borderSoft,
    required this.buttonBackground,
    required this.buttonForeground,
  });

  factory AppColors.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppColors(
      isDark: isDark,
      primary: ColorManager.getPrimary(isDark),
      secondary: ColorManager.getSecondary(isDark),
      background: ColorManager.getBackground(isDark),
      backgroundSecondary: ColorManager.getBackgroundSecondary(isDark),
      textPrimary: ColorManager.getTextPrimary(isDark),
      textSecondary: ColorManager.getTextSecondary(isDark),
      textTitle: ColorManager.getPrimary(isDark),
      cardBackground: isDark ? ColorManager.backgroundSecondary : ColorManager.white,
      borderWeak: ColorManager.getBorderWeak(isDark),
      borderSoft: ColorManager.getBorderSoft(isDark),
      buttonBackground: ColorManager.getButtonBackground(isDark),
      buttonForeground: ColorManager.getButtonForeground(isDark),
    );
  }
}

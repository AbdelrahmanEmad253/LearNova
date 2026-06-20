import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnova/core/constants/app_dimensions.dart';
import 'package:learnova/core/theme/app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.poppinsTextTheme(base);
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: ColorManager.primary,
        secondary: ColorManager.backgroundSecondary,
        surface: ColorManager.secondary,
        error: ColorManager.error,
      ),
      primaryColor: ColorManager.primary,
      scaffoldBackgroundColor: ColorManager.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ColorManager.textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ColorManager.backgroundSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: const BorderSide(color: ColorManager.borderWeak),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorManager.primary;
          }
          return ColorManager.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorManager.primary.withValues(alpha: 0.38);
          }
          return ColorManager.borderWeak;
        }),
      ),
      textTheme: _buildTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorManager.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: ColorManager.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: ColorManager.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(color: ColorManager.textSecondary),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ColorManager.borderSoft),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ColorManager.primary),
        ),
        suffixIconColor: ColorManager.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorManager.white,
          foregroundColor: ColorManager.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: ColorManager.white,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: ColorManager.primary,
        secondary: ColorManager.backgroundSecondary,
        surface: ColorManager.surface,
        error: ColorManager.error,
      ),
      primaryColor: ColorManager.primary,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ColorManager.textOnLight,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: ColorManager.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: const BorderSide(color: ColorManager.lightGrey),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorManager.primary;
          }
          return ColorManager.darkGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ColorManager.primary.withValues(alpha: 0.38);
          }
          return ColorManager.lightGrey;
        }),
      ),
      textTheme: _buildTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorManager.textOnLight,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: ColorManager.textOnLight,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: ColorManager.darkGrey,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(color: ColorManager.darkGrey),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ColorManager.lightGrey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ColorManager.primary),
        ),
        suffixIconColor: ColorManager.darkGrey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorManager.secondary,
          foregroundColor: ColorManager.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: ColorManager.secondary,
      ),
    );
  }
}

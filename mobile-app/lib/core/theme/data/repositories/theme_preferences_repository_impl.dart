import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnova/core/theme/domain/repositories/theme_preferences_repository.dart';

class ThemePreferencesRepositoryImpl implements ThemePreferencesRepository {
  static const _themeKey = 'theme_mode';

  final SharedPreferences prefs;

  const ThemePreferencesRepositoryImpl(this.prefs);

  @override
  ThemeMode loadThemeMode() {
    try {
      final themeIndex = prefs.getInt(_themeKey);
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        return ThemeMode.values[themeIndex];
      }
    } catch (_) {
      // Clean up legacy invalid values and fall back to default.
      prefs.remove(_themeKey);
    }

    return ThemeMode.dark;
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) {
    return prefs.setInt(_themeKey, mode.index);
  }
}

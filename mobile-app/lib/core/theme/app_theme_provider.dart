import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/theme/data/repositories/theme_preferences_repository_impl.dart';
import 'package:learnova/core/theme/domain/repositories/theme_preferences_repository.dart';

final themePreferencesRepositoryProvider =
    Provider<ThemePreferencesRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemePreferencesRepositoryImpl(prefs);
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.watch(themePreferencesRepositoryProvider).loadThemeMode();
  }

  Future<void> toggleTheme(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    await ref.read(themePreferencesRepositoryProvider).saveThemeMode(newMode);
  }
}

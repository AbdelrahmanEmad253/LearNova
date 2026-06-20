import 'package:flutter/material.dart';

abstract class ThemePreferencesRepository {
  ThemeMode loadThemeMode();

  Future<void> saveThemeMode(ThemeMode mode);
}

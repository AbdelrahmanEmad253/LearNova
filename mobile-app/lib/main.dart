import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/auth/presentation/screens/login_screen.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/core/navigation/initial_routing_screen.dart';
import 'package:learnova/core/theme/app_theme.dart';
import 'package:learnova/core/theme/app_theme_provider.dart';
import 'package:learnova/core/services/supabase/supabase_config.dart';

import 'package:learnova/core/presentation/screens/splash_screen.dart';
import 'package:learnova/features/assessment/presentation/screens/mitchy_results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep watching to ensure the auth stream is active
    ref.watch(authSessionStreamProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learnova',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/features/auth/domain/entities/auth_session.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/main.dart';

void main() {
  testWidgets('MyApp renders Home screen smoke test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authSessionStreamProvider.overrideWith(
            (ref) => Stream<AuthSession?>.value(
              const AuthSession(userId: 'test-user'),
            ),
          ),
          currentSessionProvider.overrideWith(
            (ref) => const AuthSession(userId: 'test-user'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Novice'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/features/assessment/presentation/providers/assessment_providers.dart';
import 'package:learnova/features/assessment/presentation/screens/assessment_map_screen.dart';
import 'package:learnova/features/assessment/presentation/screens/test_description_screen.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';

class InitialRoutingScreen extends ConsumerWidget {
  const InitialRoutingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnosticResultsAsync = ref.watch(diagnosticResultsProvider);

    return diagnosticResultsAsync.when(
      data: (results) {
        final completedCount = results.length;

        // If all 5 tests are completed, go to the main home screen
        if (completedCount >= 5) {
          return const MainNavigationScreen();
        }

        // If no tests are completed, start the assessment flow from the map
        if (completedCount == 0) {
          return const AssessmentMapScreen();
        }

        // If partial tests are completed, resume from the next test
        // The index is 0-based, so completedCount corresponds to the exact test index to resume.
        return TestDescriptionScreen(testIndex: completedCount);
      },
      loading: () {
        final colors = AppColors.of(context);
        return Scaffold(
          backgroundColor: colors.background,
          body: Center(
            child: CircularProgressIndicator(color: colors.primary),
          ),
        );
      },
      error: (error, stack) {
        // Fallback to MainNavigationScreen in case of error fetching results
        return const MainNavigationScreen();
      },
    );
  }
}

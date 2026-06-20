import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/di/app_providers.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/presentation/providers/assessment_providers.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/features/assessment/presentation/screens/mitchy_results_screen.dart';

import '../../../../core/widgets/app_background.dart';
class FinalResultsSummaryScreen extends ConsumerWidget {
  const FinalResultsSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(assessmentTestsProvider);
    final resultsAsync = ref.watch(diagnosticResultsProvider);
    final colors = AppColors.of(context);

    return testsAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Text('Error loading tests: $e', style: TextStyle(color: colors.textPrimary)),
        ),
      ),
      data: (tests) {
        return resultsAsync.when(
          loading: () => Scaffold(
            backgroundColor: colors.background,
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          ),
          error: (e, _) => Scaffold(
            backgroundColor: colors.background,
            body: Center(
              child: Text('Error loading results: $e', style: TextStyle(color: colors.textPrimary)),
            ),
          ),
          data: (results) {
            // Filter to keep only the latest result for each test_number
            final Map<int, Map<String, dynamic>> latestResultsMap = {};
            for (final res in results) {
              final int testNum = res['test_number'] as int;
              if (!latestResultsMap.containsKey(testNum)) {
                latestResultsMap[testNum] = res;
              } else {
                // If this row is newer, replace the existing one
                final currentCompletedAt = DateTime.parse(latestResultsMap[testNum]!['completed_at'].toString());
                final newCompletedAt = DateTime.parse(res['completed_at'].toString());
                if (newCompletedAt.isAfter(currentCompletedAt)) {
                  latestResultsMap[testNum] = res;
                }
              }
            }

            final filteredResults = latestResultsMap.values.toList()
              ..sort((a, b) => (a['test_number'] as int).compareTo(b['test_number'] as int));

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  const Positioned.fill(child: AppBackground()),
                  // 1. Background Bubbles (PNGs)
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.asset(AppAssets.testCircleUp, width: 300),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: -80,
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(AppAssets.testCircleDown, width: 350),
                    ),
                  ),
                  Positioned(
                    top: 250,
                    left: 10,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(AppAssets.testSmallCircle, width: 120),
                    ),
                  ),

                  // 2. Content Layer
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 30),
                        child: Column(
                          children: [
                            const SizedBox(height: 100),

                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [
                                // Card Container
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: colors.cardBackground,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(32),
                                      topRight: Radius.circular(32),
                                      bottomLeft: filteredResults.isEmpty ? Radius.circular(32) : Radius.zero,
                                      bottomRight: filteredResults.isEmpty ? Radius.circular(32) : Radius.zero,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 135),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'AI Analysis Results:',
                                            style: TextStyle(
                                              color: colors.textPrimary,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(Icons.refresh, color: colors.primary),
                                            onPressed: () => ref.invalidate(diagnosticResultsProvider),
                                            tooltip: 'Refresh Results',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (filteredResults.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'No analyzed results found yet.\nPlease wait for the AI analysis.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: colors.textPrimary, fontSize: 16),
                                          ),
                                        ),
                                      if (filteredResults.isEmpty || filteredResults.any((r) => r['computed_scores'] == null))
                                        TextButton.icon(
                                          onPressed: () async {
                                            try {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting AI manually...')));
                                              await ref.read(learnovaApiServiceProvider).runScoringEngine();
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Analysis triggered successfully!'), backgroundColor: Colors.green));
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                                            }
                                          },
                                          icon: const Icon(Icons.refresh, size: 16),
                                          label: const Text('Still processing? Click here to retry AI'),
                                        ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),

                                // Avatar
                                Positioned(
                                  top: -151,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 270,
                                        height: 270,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colors.primary
                                              .withValues(alpha: 0.14)
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      ClipOval(
                                        child: SvgPicture.asset(
                                          AppAssets.avatar1,
                                          width: 226,
                                          height: 226,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Results List from Python computed_scores
                            if (filteredResults.isNotEmpty)
                              Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(32),
                                    bottomRight: Radius.circular(32),
                                  ),
                                ),
                                child: Column(
                                  children: filteredResults.map((res) {
                                    final testNum = res['test_number'] as int;
                                    final computed = res['computed_scores'] as Map<String, dynamic>?;
                                    
                                    // Find the matching test entity for icon and background
                                    final testEntity = tests[testNum - 1];

                                    return _buildResultRow(
                                      context, 
                                      testEntity, 
                                      _extractResultValue(computed),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 40),

                            CustomButton(
                              text: 'Finish',
                              onPressed: () {
                                String track = 'Undetermined Track';
                                String diploma = 'General Diploma';
                                
                                if (filteredResults.isNotEmpty) {
                                  for (var res in filteredResults) {
                                    final computed = res['computed_scores'] as Map<String, dynamic>?;
                                    if (computed != null) {
                                      if (computed.containsKey('assigned_track')) {
                                        track = computed['assigned_track'].toString();
                                      }
                                      if (computed.containsKey('diploma_name')) {
                                        diploma = computed['diploma_name'].toString();
                                      } else if (computed.containsKey('dominant_style')) {
                                        diploma = "${computed['dominant_style']} Diploma";
                                      }
                                    }
                                  }
                                }

                                AppRouter.pushReplacement(
                                  context,
                                  MitchyResultsScreen(diplomaName: diploma, trackName: track),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _extractResultValue(Map<String, dynamic>? computed) {
    if (computed == null) return 'Processing...';
    
    // 1. If Python added a specific label
    if (computed.containsKey('result_label')) return computed['result_label'].toString();
    
    // 2. Handle specific exam types from your Python script
    if (computed['status'] == 'scored') {
      if (computed.containsKey('dominant_style')) return computed['dominant_style'].toString();
      if (computed.containsKey('assigned_track')) return computed['assigned_track'].toString();
      
      // Default success message if status is scored
      return 'Analyzed';
    }

    return 'Processing...';
  }

  Widget _buildResultRow(BuildContext context, AssessmentTest test, String resultValue) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      height: 72,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(test.backgroundImagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            SvgPicture.asset(
              test.iconPath,
              width: 24,
              height: 24,
              colorFilter:
                  ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                test.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              resultValue,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

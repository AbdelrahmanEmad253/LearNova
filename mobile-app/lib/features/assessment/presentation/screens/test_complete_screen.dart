import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/presentation/providers/assessment_providers.dart';
import 'package:learnova/features/assessment/presentation/screens/test_description_screen.dart';
import 'package:learnova/features/assessment/presentation/screens/final_results_summary_screen.dart';
import 'package:learnova/core/navigation/main_navigation_screen.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';
import 'package:learnova/features/profile/presentation/providers/profile_providers.dart';
import 'package:learnova/features/auth/presentation/providers/auth_providers.dart';
import 'package:learnova/core/constants/app_assets.dart';

class TestCompleteScreen extends ConsumerStatefulWidget {
  final int testIndex;
  final bool returnToMapOnContinue;
  final String? standaloneTitle;
  final int? scorePercentage;
  final String? sourceNodeId;
  final bool? didPass;
  final Future<Map<String, dynamic>>? evaluationFuture;

  const TestCompleteScreen({
    super.key,
    required this.testIndex,
    this.returnToMapOnContinue = false,
    this.standaloneTitle,
    this.scorePercentage,
    this.sourceNodeId,
    this.didPass,
    this.evaluationFuture,
  });

  @override
  ConsumerState<TestCompleteScreen> createState() => _TestCompleteScreenState();
}

class _TestCompleteScreenState extends ConsumerState<TestCompleteScreen> {
  @override
  Widget build(BuildContext context) {
    final testsAsync = ref.watch(assessmentTestsProvider);
    final colors = AppColors.of(context);

    return testsAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Text('Error: $e', style: TextStyle(color: colors.textPrimary)),
        ),
      ),
      data: (tests) => _buildContent(context, tests),
    );
  }

  Widget _buildContent(BuildContext context, List<AssessmentTest> tests) {
    final colors = AppColors.of(context);

    if (tests.isEmpty || widget.testIndex >= tests.length) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: Text(
            'No result data found.',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      );
    }

    final Size size = MediaQuery.of(context).size;
    final currentResult = tests[widget.testIndex];
    final bool isLastTest = widget.testIndex == tests.length - 1;
    final String title = widget.standaloneTitle ?? currentResult.title;

    if (widget.evaluationFuture != null) {
      return FutureBuilder<Map<String, dynamic>>(
        future: widget.evaluationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context, currentResult, size, title, colors);
          }
          if (snapshot.hasError) {
            return _buildResultState(context, currentResult, size, title, null, false, 0, tests, isLastTest, snapshot.error.toString(), colors);
          }
          
          final data = snapshot.data;
          final int score = (data?['score'] as num?)?.toInt() ?? 0;
          final bool passed = (data?['passed'] as bool?) ?? false;
          final int xp = (data?['xp_awarded'] as num?)?.toInt() ?? (data?['xp'] as num?)?.toInt() ?? 0;
          return _buildResultState(context, currentResult, size, title, score, passed, xp, tests, isLastTest, null, colors);
        },
      );
    } else {
      return _buildResultState(context, currentResult, size, title, widget.scorePercentage, widget.didPass, 100, tests, isLastTest, null, colors);
    }
  }

  Widget _buildLoadingState(BuildContext context, AssessmentTest currentResult, Size size, String title, AppColors colors) {
    return SpaceScaffold(
      topWavePaths: const [AppAssets.testStartTop],
      bottomWavePaths: const [AppAssets.testMiniBottom],
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
                children: [
                  const SizedBox(height: 60),
                  SvgPicture.asset(
                    currentResult.iconPath,
                    width: 80,
                    height: 80,
                    colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(flex: 2),
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'We are evaluating your exam...\nPlease wait a few moments.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textPrimary, fontSize: 18, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
            ),
          ));

  }

  Widget _buildResultState(BuildContext context, AssessmentTest currentResult, Size size, String title, int? scorePercentage, bool? didPass, int xpEarned, List<AssessmentTest> tests, bool isLastTest, String? error, AppColors colors) {
    final bool showNumericScore = scorePercentage != null;

    return SpaceScaffold(
      topWavePaths: const [AppAssets.testStartTop],
      bottomWavePaths: const [AppAssets.testMiniBottom],
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
                children: [
                  const SizedBox(height: 60),
                  SvgPicture.asset(
                    currentResult.iconPath,
                    width: 80,
                    height: 80,
                    colorFilter:
                        ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$title Completed!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade400, fontSize: 14),
                    ),
                  ],
                  const Spacer(flex: 2),
                  if (showNumericScore) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        'Your Score:',
                        style: TextStyle(
                          color: colors.buttonForeground,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${scorePercentage.clamp(0, 100)}%',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: colors.primary.withValues(alpha: 0.8),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      currentResult.resultDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentResult.resultTitle,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: colors.primary.withValues(alpha: 0.8),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.cardBackground.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '+$xpEarned EXP points gained!',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  if (!widget.returnToMapOnContinue)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: index <= widget.testIndex
                                ? colors.primary
                                : colors.borderWeak,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: widget.returnToMapOnContinue
                        ? 'Back to levels'
                        : (isLastTest ? 'Finish All Quizzes' : 'Next Quiz'),
                    onPressed: () {
                      if (widget.returnToMapOnContinue) {
                        if (didPass == true &&
                            widget.sourceNodeId != null) {
                          ref
                              .read(mapUnlockProvider.notifier)
                              .markPassed(widget.sourceNodeId!);
                          ref.invalidate(globalMapProvider);
                        }
                        ref.invalidate(studentProfileProvider);
                        ref.invalidate(profileDataProvider);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScreen(),
                            settings:
                                const RouteSettings(name: AppRoutePaths.home),
                          ),
                          (route) => false,
                        );
                      } else if (isLastTest) {
                        AppRouter.pushReplacement(
                          context,
                          const FinalResultsSummaryScreen(),
                          routeName: AppRoutePaths.finalResults,
                        );
                      } else {
                        AppRouter.push(
                          context,
                          TestDescriptionScreen(
                              testIndex: widget.testIndex + 1),
                          routeName: AppRoutePaths.testDescription,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    ));
  }
}

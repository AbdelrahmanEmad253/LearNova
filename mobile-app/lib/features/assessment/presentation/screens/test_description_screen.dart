import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/presentation/providers/assessment_providers.dart';
import 'package:learnova/features/assessment/presentation/screens/test_questions_screen.dart';
import 'package:learnova/features/auth/presentation/screens/login_screen.dart';
import 'package:learnova/core/constants/app_assets.dart';

class TestDescriptionScreen extends ConsumerStatefulWidget {
  final int testIndex;

  const TestDescriptionScreen({super.key, required this.testIndex});

  @override
  ConsumerState<TestDescriptionScreen> createState() =>
      _TestDescriptionScreenState();
}

class _TestDescriptionScreenState extends ConsumerState<TestDescriptionScreen> {
  List<Map<String, dynamic>>? _questions;
  bool _isLoadingQuestions = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Questions are loaded after tests resolve (see _loadQuestions).
  }

  Future<void> _loadQuestions(String testId) async {
    try {
      final diagnosticDS = ref.read(diagnosticRemoteDataSourceProvider);
      final questions = await diagnosticDS.fetchDiagnosticQuestions(testId);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoadingQuestions = false;
        });
      }
    }
  }

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
      data: (tests) {
        if (tests.isEmpty || widget.testIndex >= tests.length) {
          return Scaffold(
            backgroundColor: colors.background,
            body: Center(
              child: Text(
                'No test details found.',
                style: TextStyle(color: colors.textPrimary),
              ),
            ),
          );
        }

        final AssessmentTest currentTest = tests[widget.testIndex];
        final AssessmentTest nextTest =
            tests[(widget.testIndex + 1) % tests.length];
        final isLastTest = widget.testIndex == tests.length - 1;

        // Trigger question loading once per test.
        if (_questions == null && _isLoadingQuestions && _loadError == null) {
          _loadQuestions(currentTest.id);
        }

        if (_isLoadingQuestions) {
          return Scaffold(
            backgroundColor: colors.background,
            body:
                Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }

        if (_loadError != null) {
          return Scaffold(
            backgroundColor: colors.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Failed to load questions for ${currentTest.id}.\n$_loadError',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textPrimary),
                ),
              ),
            ),
          );
        }

        final questions = _questions ?? const <Map<String, dynamic>>[];
        final questionsCount = questions.length;

        return SpaceScaffold(
          topWavePaths: [AppAssets.testStartTop],
          bottomWavePaths: [AppAssets.testStartBottom],
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Test Description',
              style: TextStyle(color: colors.textSecondary, fontSize: 18),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: colors.textPrimary, size: 20),
              onPressed: () => AppRouter.pop(context),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    currentTest.iconPath,
                    width: 80,
                    height: 80,
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentTest.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    currentTest.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Test Status:',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined,
                          color: ColorManager.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '$questionsCount Questions',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!isLastTest) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            colors.primary.withValues(alpha: 0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Up next:',
                              style: TextStyle(
                                color: colors.isDark
                                    ? colors.buttonForeground
                                    : colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(2),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  nextTest.iconPath,
                                  width: 30,
                                  height: 30,
                                  colorFilter: ColorFilter.mode(
                                      colors.buttonForeground, BlendMode.srcIn),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nextTest.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: colors.isDark ? colors.buttonForeground : colors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  CustomButton(
                    text: 'Take test',
                    backgroundColor: colors.buttonBackground,
                    onPressed: questionsCount > 0
                        ? () async {
                            try {
                              final diagnosticDS =
                                  ref.read(diagnosticRemoteDataSourceProvider);
                              await diagnosticDS
                                  .ensureDiagnosticSubmissionSession();

                              if (!context.mounted) {
                                return;
                              }

                              AppRouter.push(
                                context,
                                TestQuestionsScreen(
                                  testIndex: widget.testIndex,
                                  diagnosticTestTypeId: currentTest.id,
                                  initialQuestions: questions,
                                  totalQuestions: questionsCount,
                                ),
                                routeName: AppRoutePaths.testQuestions,
                              );
                            } catch (_) {
                              if (!context.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please login first to save your test result.',
                                  ),
                                  backgroundColor: ColorManager.error,
                                ),
                              );

                              final loggedIn =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen.returning(),
                                  settings: const RouteSettings(
                                    name: AppRoutePaths.login,
                                  ),
                                ),
                              );

                              if (loggedIn == true && context.mounted) {
                                AppRouter.push(
                                  context,
                                  TestQuestionsScreen(
                                    testIndex: widget.testIndex,
                                    diagnosticTestTypeId: currentTest.id,
                                    initialQuestions: questions,
                                    totalQuestions: questionsCount,
                                  ),
                                  routeName: AppRoutePaths.testQuestions,
                                );
                              }
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

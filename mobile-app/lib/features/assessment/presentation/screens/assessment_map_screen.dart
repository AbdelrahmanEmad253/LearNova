import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_durations.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/features/assessment/domain/entities/assessment_test.dart';
import 'package:learnova/features/assessment/presentation/providers/assessment_providers.dart';
import 'package:learnova/features/assessment/presentation/screens/testing_format_screen.dart';
import 'package:learnova/core/constants/app_assets.dart';

class AssessmentMapScreen extends ConsumerStatefulWidget {
  const AssessmentMapScreen({super.key});

  @override
  ConsumerState<AssessmentMapScreen> createState() =>
      _AssessmentMapScreenState();
}

class _AssessmentMapScreenState extends ConsumerState<AssessmentMapScreen> {
  late PageController _pageController;
  static const int _initialPage = 1000;
  int _currentPageIndex = 2;
  late int _currentActivePage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentActivePage = _initialPage + 2;
    _pageController = PageController(
      viewportFraction: 0.55,
      initialPage: _currentActivePage,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        _currentActivePage++;
        _pageController.animateToPage(
          _currentActivePage,
          duration: AppDurations.verySlow,
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
          child: Text(
            'Error loading tests: $e',
            style: TextStyle(color: colors.textPrimary),
          ),
        ),
      ),
      data: (tests) {
        if (tests.isEmpty) {
          return Scaffold(
            backgroundColor: colors.background,
            body: Center(
              child: Text(
                'No tests found.',
                style: TextStyle(color: colors.textPrimary),
              ),
            ),
          );
        }

        if (_currentPageIndex >= tests.length) {
          _currentPageIndex = 0;
        }

        return SpaceScaffold(
          topWavePaths: [AppAssets.testStartTop],
          bottomWavePaths: [AppAssets.testStartBottom],
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                Text(
                  'Tests Map',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  height: 320,
                  child: AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      return PageView.builder(
                        controller: _pageController,
                        onPageChanged: (value) {
                          setState(() {
                            _currentActivePage = value;
                            _currentPageIndex = value % tests.length;
                          });
                        },
                        itemBuilder: (context, index) {
                          final categoryIndex = index % tests.length;
                          final test = tests[categoryIndex];

                          double relativePosition = 0;
                          if (_pageController.position.haveDimensions) {
                            relativePosition = index - _pageController.page!;
                          } else {
                            relativePosition =
                                (index - _currentActivePage).toDouble();
                          }

                          double absPos = relativePosition.abs();
                          double yOffset = math.pow(absPos, 2) * 35;
                          double scale = (1 - (absPos * 0.3)).clamp(0.5, 1.1);
                          double opacity = (1 - (absPos * 0.4)).clamp(0.3, 1.0);

                          return Transform.translate(
                            offset: Offset(0, yOffset),
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity,
                                child: Center(
                                  child: _buildCategoryCard(
                                      context, test, absPos < 0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: AnimatedSwitcher(
                    duration: AppDurations.slow,
                    child: RichText(
                      key: ValueKey<int>(_currentPageIndex),
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        children: _buildDescriptionSpans(
                            context, tests[_currentPageIndex].description),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: CustomButton(
                    text: 'Next',
                    onPressed: () {
                      AppRouter.push(
                        context,
                        const TestingFormatScreen(),
                        routeName: AppRoutePaths.testingFormat,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, AssessmentTest test, bool isActive) {
    final colors = AppColors.of(context);

    return Container(
      width: 250,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isActive
            ? LinearGradient(
                colors: [colors.primary, colors.backgroundSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : colors.cardBackground.withValues(alpha: 0.45),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            test.iconPath,
            width: 60,
            height: 60,
            colorFilter: ColorFilter.mode(
              isActive ? colors.buttonForeground : colors.textSecondary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              test.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    isActive ? colors.buttonForeground : colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildDescriptionSpans(BuildContext context, String text) {
    final colors = AppColors.of(context);
    final parts = text.split('expert researchers');
    if (parts.length > 1) {
      return [
        TextSpan(text: parts[0]),
        TextSpan(
          text: 'expert researchers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        TextSpan(text: parts[1]),
      ];
    }
    return [TextSpan(text: text)];
  }
}

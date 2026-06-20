import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_durations.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/onboarding/domain/entities/intro_step.dart';
import 'package:learnova/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:learnova/features/assessment/presentation/screens/assessment_map_screen.dart';

class IntroStepsScreen extends ConsumerStatefulWidget {
  const IntroStepsScreen({super.key});

  @override
  ConsumerState<IntroStepsScreen> createState() => _IntroStepsScreenState();
}

class _IntroStepsScreenState extends ConsumerState<IntroStepsScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<IntroStep> steps = ref.watch(introStepsProvider);
    return SpaceScaffold(
      extendBodyBehindAppBar: true,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: PageView.builder(
          controller: _pageController,
          itemCount: steps.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return _buildPage(steps[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPage(IntroStep data) {
    final colors = AppColors.of(context);
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SvgPicture.asset(
            data.topWavePath,
            fit: BoxFit.fitWidth,
            colorFilter: colors.isDark ? null : ColorFilter.mode(colors.primary.withValues(alpha: 0.3), BlendMode.srcIn),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SvgPicture.asset(
            data.bottomWavePath,
            fit: BoxFit.fitWidth,
            colorFilter: colors.isDark ? null : ColorFilter.mode(colors.primary.withValues(alpha: 0.3), BlendMode.srcIn),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Builder(builder: (context) {
                  final String currentIconPath =
                      (colors.isDark || data.lightIconPath == null)
                          ? data.iconPath
                          : data.lightIconPath!;
                  final bool isCurrentSvg =
                      (colors.isDark || data.lightIconPath == null)
                          ? data.isSvg
                          : (data.lightIconPath!.endsWith('.svg'));

                  return isCurrentSvg
                      ? SvgPicture.asset(
                          currentIconPath,
                          height: 220,
                        )
                      : Image.asset(currentIconPath, height: 220);
                }),
                const SizedBox(height: 40),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      List.generate(3, (index) => _buildStepIndicator(index, colors)),
                ),
                const SizedBox(height: 32),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 16,
                      height: 1.5),
                ),
                const Spacer(),
                if (_currentIndex > 0) ...[
                  CustomButton(
                    text: 'Back',
                    isOutlined: true,
                    onPressed: () {
                      _pageController.previousPage(
                        duration: AppDurations.medium,
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                CustomButton(
                  text: _currentIndex == 2 ? 'Get Started' : 'Next',
                  backgroundColor: colors.buttonBackground,
                  onPressed: () {
                    if (_currentIndex < 2) {
                      _pageController.nextPage(
                        duration: AppDurations.medium,
                        curve: Curves.easeInOut,
                      );
                    } else {
                      AppRouter.push(
                        context,
                        const AssessmentMapScreen(),
                        routeName: AppRoutePaths.assessmentMap,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int index, AppColors colors) {
    final bool isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: AppDurations.medium,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: isSelected ? 48 : 24,
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary
            : (colors.isDark
                ? colors.borderWeak
                : colors.borderSoft.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/features/onboarding/presentation/screens/intro_steps_screen.dart';
import 'package:learnova/core/constants/app_assets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SpaceScaffold(
      topWavePaths: [AppAssets.welcomingTop1],
      bottomWavePaths: [AppAssets.welcomingBottom1],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Star Icon
              SvgPicture.asset(
                AppAssets.starIcon,
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 40),
              // Welcome Title
              Text(
                'Welcome to',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Learnova!',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Description Text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Our platform is designed to understand how you ',
                    ),
                    const TextSpan(
                      text: 'think, learn,',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' and '),
                    const TextSpan(
                      text: 'grow; ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          'guiding you toward the computer science path that aligns with your strengths and ambitions!',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Our main goal is ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                          'to give you a mentorship experience that adapts to you — your pace, your style, and your future goals in tech.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "Let's shape the path that fits you best!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Next Button
              CustomButton(
                text: 'Next',
                backgroundColor: colors.buttonBackground,
                onPressed: () {
                  AppRouter.push(
                    context,
                    const IntroStepsScreen(),
                    routeName: AppRoutePaths.onboardingIntroSteps,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

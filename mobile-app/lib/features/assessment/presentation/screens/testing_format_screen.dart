import 'package:flutter/material.dart';
import 'package:learnova/core/constants/app_durations.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/widgets/space_scaffold.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/assessment/presentation/screens/test_description_screen.dart';
import 'package:learnova/core/constants/app_assets.dart';
// import 'test_description_screen.dart'; // سأقوم بإنشائه بعد قليل

class TestingFormatScreen extends StatefulWidget {
  const TestingFormatScreen({super.key});

  @override
  State<TestingFormatScreen> createState() => _TestingFormatScreenState();
}

class _TestingFormatScreenState extends State<TestingFormatScreen> {
  int? _selectedFormat; // 0 for Within App, 1 for On Browser

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SpaceScaffold(
      topWavePaths: [AppAssets.testStartTop],
      bottomWavePaths: [AppAssets.testStartBottom],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Testing Format',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Select how are you taking the assessment tests:',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const Spacer(),

              // Format Options
              _buildFormatCard(
                colors: colors,
                index: 0,
                title: 'Within App',
                icon: Icons.smartphone_outlined,
                isSelected: _selectedFormat == 0,
              ),
              const SizedBox(height: 24),
              _buildFormatCard(
                colors: colors,
                index: 1,
                title: 'On Browser',
                icon: Icons.language_outlined,
                isSelected: _selectedFormat == 1,
              ),

              const Spacer(),

              // P.S Text
              RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 18,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'P.S: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary),
                    ),
                    TextSpan(
                      text: 'Your progress in the tests is actively saved, so ',
                    ),
                    TextSpan(
                      text: 'abrupt exiting and resuming',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary),
                    ),
                    TextSpan(
                      text: ' won\'t be much trouble',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Next Button
              CustomButton(
                text: 'Next',
                backgroundColor: colors.buttonBackground,
                onPressed: _selectedFormat != null
                    ? () {
                        AppRouter.push(
                          context,
                          const TestDescriptionScreen(testIndex: 0),
                          routeName: AppRoutePaths.testDescription,
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCard({
    required AppColors colors,
    required int index,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    final Color contentColor = isSelected
        ? colors.buttonForeground
        : (colors.isDark ? colors.buttonForeground : const Color(0xFF01172E));

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = index;
        });
      },
      child: AnimatedContainer(
        duration: AppDurations.medium,
        width: 162,
        height: 178,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 10,
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: contentColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: contentColor,
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

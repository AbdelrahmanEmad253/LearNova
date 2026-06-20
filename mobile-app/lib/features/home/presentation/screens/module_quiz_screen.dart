import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/assessment/presentation/screens/test_questions_screen.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';

class ModuleQuizScreen extends StatelessWidget {
  final LevelModule module;
  final String? quizId;
  final int questionCount;

  const ModuleQuizScreen({
    super.key,
    required this.module,
    this.quizId,
    this.questionCount = 3,
  });

  void _backToLevels(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) =>
          route.settings.name == AppRoutePaths.homeLevelModules ||
          route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(),
          ),
          if (colors.isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF01172E).withValues(alpha: 0.72),
                      const Color(0xFF01172E).withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapScrollTop,
                width: size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapFixedTop,
                width: size.width,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            bottom: -8,
            left: -80,
            right: -80,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.preExamBottomWaveByLevel(module.levelNumber),
                width: size.width + 160,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Level ${module.levelNumber} - Module ${module.moduleNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      '(Quiz)',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _MetaRow(
                      icon: Icons.description_outlined,
                      text: '$questionCount MCQ Questions',
                    ),
                    const SizedBox(height: 10),
                    const _MetaRow(
                      icon: Icons.timer_outlined,
                      text: '10 - 15 minutes',
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'This quiz involves the topics concerned with the first module:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: module.sections
                          .take(2)
                          .map((section) => _SectionChip(label: section.title))
                          .toList(growable: false),
                    ),
                    const Spacer(),
                    _PrimaryActionButton(
                      text: 'Take quiz',
                      onPressed: () {
                        // Construct the correct map node ID for unlock tracking
                        final bool isLevelExam =
                            quizId?.startsWith('exam_') ?? false;
                        final String mapNodeId = isLevelExam
                            ? 'w${module.levelNumber}_e'
                            : 'w${module.levelNumber}_l${module.moduleNumber}';
                        AppRouter.push(
                          context,
                          TestQuestionsScreen(
                            testIndex: module.moduleNumber - 1,
                            quizId: quizId ??
                                'exam_da_l${module.levelNumber}_m${module.moduleNumber}',
                            totalQuestions: questionCount,
                            returnToHomeOnFinish: true,
                            completionTitle:
                                isLevelExam ? 'Level Exam' : 'Module Test',
                            sourceNodeId: mapNodeId,
                          ),
                          routeName: AppRoutePaths.testQuestions,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _SecondaryActionButton(
                      text: 'Back to Levels',
                      onPressed: () => _backToLevels(context),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: colors.textPrimary, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;

  const _SectionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF07284B).withValues(alpha: 0.7),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF72F7D7),
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryActionButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colors.cardBackground,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SecondaryActionButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SizedBox(
      width: double.infinity,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF18D2FF), Color(0xFF0DBEDF)],
          ),
          border: Border.all(color: const Color(0xFF01172E), width: 1),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: colors.buttonForeground,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

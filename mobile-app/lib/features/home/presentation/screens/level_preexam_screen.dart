import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/features/assessment/presentation/screens/test_questions_screen.dart';

enum _Difficulty { easy, medium, hard }

class LevelPreExamScreen extends StatefulWidget {
  final int levelNumber;
  final String examId;

  const LevelPreExamScreen({
    super.key,
    required this.levelNumber,
    required this.examId,
  });

  @override
  State<LevelPreExamScreen> createState() => _LevelPreExamScreenState();
}

class _LevelPreExamScreenState extends State<LevelPreExamScreen> {
  _Difficulty _selectedDifficulty = _Difficulty.easy;

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
                AppAssets.preExamBottomWaveByLevel(widget.levelNumber),
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
                      'Level ${widget.levelNumber}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '(Exam)',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      height: 152,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF01172E).withValues(alpha: 0.28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1E121212),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const _StarCluster(),
                    ),
                    const SizedBox(height: 30),
                    _ExamMetaRow(
                      icon: Icons.description_outlined,
                      text: '3 Written Questions',
                    ),
                    const SizedBox(height: 10),
                    _ExamMetaRow(
                      icon: Icons.timer_outlined,
                      text: '10 - 15 minutes',
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.primary,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1E121212),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Select Difficulty:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF01172E),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _DifficultyChip(
                            label: 'Easy',
                            iconCount: 1,
                            selected: _selectedDifficulty == _Difficulty.easy,
                            onTap: () {
                              setState(
                                  () => _selectedDifficulty = _Difficulty.easy);
                            },
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: _DifficultyChip(
                            label: 'Medium',
                            iconCount: 2,
                            selected: _selectedDifficulty == _Difficulty.medium,
                            onTap: () {
                              setState(() =>
                                  _selectedDifficulty = _Difficulty.medium);
                            },
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: _DifficultyChip(
                            label: 'Hard',
                            iconCount: 3,
                            selected: _selectedDifficulty == _Difficulty.hard,
                            onTap: () {
                              setState(
                                  () => _selectedDifficulty = _Difficulty.hard);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _PrimaryActionButton(
                      text: 'Take exam',
                      onPressed: () {
                        AppRouter.push(
                          context,
                          TestQuestionsScreen(
                            testIndex: 0,
                            totalQuestions: 3,
                            returnToHomeOnFinish: true,
                            completionTitle: 'Level ${widget.levelNumber} Exam',
                            sourceNodeId: widget.examId,
                          ),
                          routeName: AppRoutePaths.testQuestions,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _SecondaryActionButton(
                      text: 'Back to Levels',
                      onPressed: () => AppRouter.pop(context),
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

class _StarCluster extends StatelessWidget {
  const _StarCluster();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppAssets.starIcon,
            width: 76,
            height: 76,
            colorFilter:
                const ColorFilter.mode(ColorManager.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          SvgPicture.asset(
            AppAssets.starIcon,
            width: 118,
            height: 118,
            colorFilter:
                const ColorFilter.mode(ColorManager.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 10),
          SvgPicture.asset(
            AppAssets.starIcon,
            width: 76,
            height: 76,
            colorFilter:
                const ColorFilter.mode(ColorManager.white, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}

class _ExamMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ExamMetaRow({required this.icon, required this.text});

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
          textAlign: TextAlign.center,
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

class _DifficultyChip extends StatelessWidget {
  final String label;
  final int iconCount;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.iconCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? null
                  : Border.all(
                      color: const Color(0x3F121212),
                      width: 0.5,
                    ),
              color: selected ? null : ColorManager.white,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF72F7D7), Color(0xFF03478E)],
                    )
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E121212),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      iconCount,
                      (index) => Padding(
                        padding: EdgeInsets.only(
                            right: index == iconCount - 1 ? 0 : 1),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 10,
                          color: selected
                              ? ColorManager.white
                              : const Color(0xFF01172E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? ColorManager.white
                          : const Color(0xFF01172E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

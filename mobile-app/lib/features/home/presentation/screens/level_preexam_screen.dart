import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/features/assessment/presentation/screens/test_questions_screen.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/core/services/supabase/supabase_config.dart';

enum _Difficulty { easy, medium, hard }

final selectedDifficultyProvider = StateProvider<_Difficulty>((ref) => _Difficulty.easy);

class LevelPreExamScreen extends ConsumerStatefulWidget {
  final int levelNumber;
  final String examId;
  final bool isModuleExam;
  final LevelModule? module;
  final String? mapNodeId;

  const LevelPreExamScreen({
    super.key,
    required this.levelNumber,
    required this.examId,
    required this.isModuleExam,
    this.module,
    this.mapNodeId,
  });

  @override
  ConsumerState<LevelPreExamScreen> createState() => _LevelPreExamScreenState();
}

class _LevelPreExamScreenState extends ConsumerState<LevelPreExamScreen> {
  bool _isStartingExam = false;

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
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            widget.isModuleExam
                                ? 'Level ${widget.levelNumber} - Module ${widget.module?.moduleNumber ?? ''}'
                                : 'Level ${widget.levelNumber}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: widget.isModuleExam ? 36 : 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: widget.isModuleExam ? 34 : 40),
                          Text(
                            widget.isModuleExam ? '(Quiz)' : '(Exam)',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: widget.isModuleExam ? 32 : 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (widget.isModuleExam) ...[
                            _ExamMetaRow(
                              icon: Icons.description_outlined,
                              text: 'Multiple Choice Questions',
                            ),
                            const SizedBox(height: 10),
                            _ExamMetaRow(
                              icon: Icons.timer_outlined,
                              text: '10 - 15 minutes',
                            ),
                            const SizedBox(height: 34),
                            Text(
                              'This quiz involves the topics concerned with the module:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textPrimary.withValues(alpha: 0.9),
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 26),
                            if (widget.module != null)
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: widget.module!.sections
                                    .take(2)
                                    .map((section) => _SectionChip(label: section.title))
                                    .toList(growable: false),
                              ),
                            const SizedBox(height: 24),
                          ] else ...[
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
                          ],
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
                    Consumer(
                      builder: (context, ref, child) {
                        final selectedDifficulty = ref.watch(selectedDifficultyProvider);
                        return Row(
                          children: [
                            Expanded(
                              child: _DifficultyChip(
                                label: 'Easy',
                                iconCount: 1,
                                selected: selectedDifficulty == _Difficulty.easy,
                                onTap: () {
                                  ref.read(selectedDifficultyProvider.notifier).state = _Difficulty.easy;
                                },
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: _DifficultyChip(
                                label: 'Medium',
                                iconCount: 2,
                                selected: selectedDifficulty == _Difficulty.medium,
                                onTap: () {
                                  ref.read(selectedDifficultyProvider.notifier).state = _Difficulty.medium;
                                },
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: _DifficultyChip(
                                label: 'Hard',
                                iconCount: 3,
                                selected: selectedDifficulty == _Difficulty.hard,
                                onTap: () {
                                  ref.read(selectedDifficultyProvider.notifier).state = _Difficulty.hard;
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                          const Spacer(),
                          _PrimaryActionButton(
                            text: widget.isModuleExam ? 'Take quiz' : 'Take exam',
                            isLoading: _isStartingExam,
                            onPressed: () async {
                              if (_isStartingExam) return;
                              setState(() => _isStartingExam = true);

                              try {
                                final String sourceMapNodeId;
                                if (widget.isModuleExam && widget.mapNodeId != null) {
                                  sourceMapNodeId = widget.mapNodeId!;
                                } else if (widget.isModuleExam) {
                                  sourceMapNodeId = 'w${widget.levelNumber}_l${widget.module?.moduleNumber ?? 1}';
                                } else {
                                  sourceMapNodeId = 'w${widget.levelNumber}_e';
                                }

                                final selectedDifficulty = ref.read(selectedDifficultyProvider);

                                // Dynamically fetch the correct assessment_id for the database
                                String resolvedQuizId = widget.examId;
                                if (!widget.isModuleExam) {
                                  final client = SupabaseConfig.client;
                                  
                                  // Find the correct level_id using the widget.examId we already have, 
                                  // which is the default 'mid' assessment ID from the map screen.
                                  final examData = await client
                                      .from('level_assessments')
                                      .select('level_id')
                                      .eq('id', widget.examId)
                                      .maybeSingle();

                                  if (examData != null && examData['level_id'] != null) {
                                    final levelId = examData['level_id'];
                                    
                                    // Our app expects 'medium' to map to 'mid' in the database
                                    final mappedDiff = selectedDifficulty == _Difficulty.medium 
                                        ? 'mid' 
                                        : selectedDifficulty.name;

                                    final assessmentData = await client
                                        .from('level_assessments')
                                        .select('id')
                                        .eq('level_id', levelId)
                                        .eq('difficulty', mappedDiff)
                                        .maybeSingle();

                                    if (assessmentData != null && assessmentData['id'] != null) {
                                      resolvedQuizId = assessmentData['id'].toString();
                                    }
                                  }
                                }

                                if (!mounted) return;

                                AppRouter.push(
                                  context,
                                  TestQuestionsScreen(
                                    testIndex: widget.isModuleExam
                                        ? ((widget.module?.moduleNumber ?? 1) - 1)
                                        : 0,
                                    quizId: resolvedQuizId,
                                    totalQuestions: widget.isModuleExam ? 5 : 3,
                                    returnToHomeOnFinish: true,
                                    completionTitle: widget.isModuleExam
                                        ? 'Module Test'
                                        : 'Level ${widget.levelNumber} Exam',
                                    sourceNodeId: sourceMapNodeId,
                                    isLevelExam: !widget.isModuleExam,
                                    difficulty: selectedDifficulty.name,
                                  ),
                                  routeName: AppRoutePaths.testQuestions,
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isStartingExam = false);
                                }
                              }
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
                ],
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
  final bool isLoading;

  const _PrimaryActionButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

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
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? CircularProgressIndicator(color: colors.textPrimary)
              : Text(
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

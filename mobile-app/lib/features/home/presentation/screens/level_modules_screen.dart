import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/custom_button.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/features/home/presentation/screens/module_content_screen.dart';
import 'package:learnova/features/home/presentation/screens/module_quiz_screen.dart';

import '../providers/home_providers.dart';

class LevelModulesScreen extends ConsumerWidget {
  final LevelModule module;
  final String examId;
  final bool isLastModule;
  final bool showCustomPreExam;

  const LevelModulesScreen({
    super.key,
    required this.module,
    required this.examId,
    this.isLastModule = false,
    this.showCustomPreExam = false,
  });

  Future<void> _onContinueModule(BuildContext context) async {
    await AppRouter.push(
      context,
      ModuleContentScreen(
        module: module,
        examId: examId,
        showCustomPreExam: showCustomPreExam,
        isLastModule: isLastModule,
      ),
      routeName: AppRoutePaths.homeModuleContent,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Size size = MediaQuery.of(context).size;
    final colors = AppColors.of(context);

    // Try to get the latest module data from the global map provider
    LevelModule currentModule = module;
    final mapData = ref.watch(globalMapProvider).value;
    if (mapData != null) {
      for (final level in mapData) {
        for (final m in level.modules) {
          if (m.id == module.id) {
            currentModule = m;
            break;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapTop,
                width: size.width,
                fit:BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: const Offset(0, 140),
                  child: Opacity(
                    opacity: 0.75,
                    child: SvgPicture.asset(
                      AppAssets.welcomingBottom1,
                      width: size.width,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: _buildOverviewContent(context, colors, currentModule),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewContent(BuildContext context, AppColors colors, LevelModule currentModule) {
    final sections = currentModule.sections;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              'Level ${currentModule.levelNumber} - Module ${currentModule.moduleNumber}',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              currentModule.moduleName,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              'Skill Mastery:',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            sections.isEmpty
                ? Center(
                    child: Text(
                      'No topics in this module yet.',
                      style: TextStyle(color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: sections
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _SkillMasteryColumn(
                                section: entry.value,
                                shapeHeight: 250.0, // Fixed height to prevent squishing
                                useAccent: entry.key.isEven,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 32),
            if (currentModule.progressPercentage >= 0.99 && sections.isNotEmpty) ...[
              CustomButton(
                text: 'Take Module Exam',
                onPressed: () {
                  AppRouter.push(
                    context,
                    ModuleQuizScreen(
                      module: currentModule,
                      quizId: currentModule.id,
                    ),
                    routeName: AppRoutePaths.homeLevelPreExam,
                  );
                },
                backgroundColor: colors.primary,
                textColor: colors.background,
                height: 64,
                borderRadius: 16,
              ),
              const SizedBox(height: 16),
            ],
            CustomButton(
              text: 'Continue Module',
              onPressed: () => _onContinueModule(context),
              backgroundColor: colors.buttonBackground,
              textColor: colors.buttonForeground,
              height: 64,
              borderRadius: 16,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Back to Levels',
              onPressed: () => AppRouter.pop(context),
              textColor: colors.textPrimary,
              isOutlined: true,
              height: 64,
              borderRadius: 16,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SkillMasteryColumn extends StatelessWidget {
  final ModuleSection section;
  final double shapeHeight;
  final bool useAccent;

  const _SkillMasteryColumn({
    required this.section,
    this.shapeHeight = 300,
    this.useAccent = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 100,
              height: shapeHeight,
              child: SvgPicture.asset(
                AppAssets.mapModuleShape,
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                  useAccent
                      ? ColorManager.primary.withValues(alpha: 0.3)
                      : ColorManager.uiBlue300.withValues(alpha: 0.3),
                  BlendMode.srcIn,
                ),
              ),
            ),
            ClipPath(
              clipper: _ModuleClipper(),
              child: Container(
                width: 100,
                height: shapeHeight * section.progressPercentage,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: useAccent
                        ? [ColorManager.primary, ColorManager.uiBlueGreen]
                        : [ColorManager.uiBlue300, ColorManager.uiBlue700],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 100,
              height: shapeHeight,
              child: SvgPicture.asset(
                AppAssets.mapModuleShape,
                fit: BoxFit.fill,
                colorFilter: const ColorFilter.mode(
                  ColorManager.borderWeak,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 120,
          child: Text(
            section.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(section.progressPercentage * 100).round()}%',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ModuleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.15);
    path.lineTo(size.width, size.height * 0.85);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.85);
    path.lineTo(0, size.height * 0.15);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

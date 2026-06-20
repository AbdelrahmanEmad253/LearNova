import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/navigation/app_route_paths.dart';
import 'package:learnova/core/navigation/app_router.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/app_background.dart';
import 'package:learnova/core/widgets/app_top_bar.dart';
import 'package:learnova/features/home/domain/entities/level_module.dart';
import 'package:learnova/features/home/presentation/providers/home_providers.dart';
import 'package:learnova/features/island_map/presentation/widgets/island_node_widget.dart';
import 'package:learnova/features/island_map/presentation/widgets/island_path_connector.dart';
import 'package:learnova/features/home/presentation/screens/level_modules_screen.dart';
import 'package:learnova/features/home/presentation/screens/module_quiz_screen.dart';

class IslandMapScreen extends ConsumerStatefulWidget {
  const IslandMapScreen({super.key});

  @override
  ConsumerState<IslandMapScreen> createState() => _IslandMapScreenState();
}

class _IslandMapScreenState extends ConsumerState<IslandMapScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startMapAnimation() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || !_scrollController.hasClients) return;

    // Animate upwards to Level 1 (which is at the top of the map)
    final targetOffset = 0.0;

    await _scrollController.animateTo(
      targetOffset,
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutCubic,
    );

    // After scrolling completes, slide the nav bar up
    if (mounted) {
      ref.read(isMapAnimatingProvider.notifier).state = false;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final Size size = MediaQuery.of(context).size;
    final double topPadding = MediaQuery.of(context).padding.top;

    final globalDataAsync = ref.watch(globalMapProvider);

    // Watch triggers a rebuild when data changes, so we can just check the state here
    if (globalDataAsync.hasError) {
      // Ensure nav bar is shown if map fails to load
      Future.microtask(() => ref.read(isMapAnimatingProvider.notifier).state = false);
    } else if (globalDataAsync.hasValue && !globalDataAsync.isLoading && !_hasAnimated) {
      _hasAnimated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
        _startMapAnimation();
      });
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackground(),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  SvgPicture.asset(
                    AppAssets.mapScrollTop,
                    width: size.width,
                    fit: BoxFit.fitWidth,
                    colorFilter: const ColorFilter.mode(Color(0xFF03478E), BlendMode.srcIn),
                  ),
                  globalDataAsync.when(
                    data: (levelsData) => _buildGlobalPath(context, size, levelsData, ref),
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, st) => Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Error loading map: $e',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 150), // Bottom padding
                ],
              ),
            ),
          ),
          // Fixed Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: SvgPicture.asset(
                AppAssets.mapFixedTop,
                width: size.width,
                fit: BoxFit.fitWidth,
                colorFilter: const ColorFilter.mode(Color(0xFF03478E), BlendMode.srcIn),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppTopBar(topPadding: topPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalPath(BuildContext context, Size size, List<LevelModulesData> levelsData, WidgetRef ref) {
    if (levelsData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No map data available.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    const double nodeSpacingY = 180.0;
    
    // Calculate total height
    double totalHeight = 0;
    for (final level in levelsData) {
      totalHeight += 40; // Reduced space (no title)
      totalHeight += level.modules.length * nodeSpacingY;
      if (level.isExamAvailable) {
        totalHeight += nodeSpacingY + 40; // Extra space for large centered exam
      }
    }
    totalHeight += 200;

    final pathPoints = _calculatePathPoints(size.width, nodeSpacingY, levelsData);

    return SizedBox(
      height: totalHeight,
      width: size.width,
      child: Stack(
        children: [
          // Build Paths
          Positioned.fill(
            child: CustomPaint(
              painter: IslandPathConnector(
                points: pathPoints,
              ),
            ),
          ),
          
          // Build Islands (No Titles)
          ..._buildAllNodes(context, size.width, nodeSpacingY, levelsData, ref),
        ],
      ),
    );
  }

  List<Offset> _calculatePathPoints(double screenWidth, double spacingY, List<LevelModulesData> levelsData) {
    final List<Offset> points = [];
    final double centerX = screenWidth / 2;
    final double xOffset = screenWidth * 0.25;

    int globalIndex = 0;
    double currentY = 100.0;

    for (final level in levelsData) {
      currentY += 40; // spacing between levels
      
      for (int i = 0; i < level.modules.length; i++) {
        final double x = (globalIndex % 2 == 0) ? centerX - xOffset : centerX + xOffset;
        points.add(Offset(x, currentY));
        currentY += spacingY;
        globalIndex++;
      }

      if (level.isExamAvailable) {
        // Exam is always centered
        points.add(Offset(centerX, currentY));
        currentY += spacingY + 40;
        globalIndex++;
      }
    }

    return points;
  }

  List<Widget> _buildAllNodes(BuildContext context, double screenWidth, double spacingY, List<LevelModulesData> levelsData, WidgetRef ref) {
    final List<Widget> nodes = [];
    final double centerX = screenWidth / 2;
    final double xOffset = screenWidth * 0.25;
    final unlockNotifier = ref.watch(mapUnlockProvider.notifier);

    int globalIndex = 0;
    double currentY = 100.0;

    for (final level in levelsData) {
      currentY += 40;

      // Add Module Islands
      for (int i = 0; i < level.modules.length; i++) {
        final module = level.modules[i];
        final bool isLeft = globalIndex % 2 == 0;
        final String asset = isLeft 
            ? AppAssets.islandLeft(level.levelNumber) 
            : AppAssets.islandRight(level.levelNumber);

        final double x = isLeft ? centerX - xOffset : centerX + xOffset;
        final String nodeId = 'w${level.levelNumber}_l${i + 1}';
        final bool isUnlocked = unlockNotifier.isUnlocked(nodeId);
        final bool isLocked = !isUnlocked;
        
        nodes.add(
          Positioned(
            left: x - 115, // center-adjustment for larger size
            top: currentY - 115,
            child: IslandNodeWidget(
              imageAsset: asset,
              size: 230,
              levelNumber: level.levelNumber,
              isLeft: isLeft,
              sequentialModuleNumber: i + 1, // Sequential within level (1, 2, 3...)
              isLocked: isLocked,
              onTap: () {
                AppRouter.push(
                  context,
                  LevelModulesScreen(
                    module: module,
                    examId: level.examId,
                    isLastModule:
                        module.moduleNumber == level.modules.length,
                  ),
                  routeName: AppRoutePaths.homeLevelModules,
                );
              },
            ),
          ),
        );

        currentY += spacingY;
        globalIndex++;
      }

      // Add Exam Island (Centered and Bigger)
      if (level.isExamAvailable) {
        final String asset = AppAssets.islandExam(level.levelNumber);
        final String examNodeId = 'w${level.levelNumber}_e';
        final bool isLocked = !unlockNotifier.isUnlocked(examNodeId);
        
        nodes.add(
          Positioned(
            left: centerX - 175,
            top: currentY - 175,
            child: IslandNodeWidget(
              imageAsset: asset,
              size: 350, // Massive
              levelNumber: level.levelNumber,
              isExam: true,
              isLocked: isLocked,
              onTap: () {
                AppRouter.push(
                  context,
                  ModuleQuizScreen(
                    module: level.modules.isNotEmpty ? level.modules.first : LevelModule(
                      id: '', levelNumber: level.levelNumber, moduleNumber: 0, moduleName: '', courseTitle: '', sections: [], contentItems: [], progressPercentage: 0
                    ),
                    quizId: level.examId,
                  ),
                  routeName: AppRoutePaths.homeLevelPreExam,
                );
              },
            ),
          ),
        );

        currentY += spacingY + 40;
        globalIndex++;
      }
    }

    return nodes;
  }
}

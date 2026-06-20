import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/constants/app_assets.dart';

class IslandNodeWidget extends StatelessWidget {
  final String imageAsset;
  final VoidCallback onTap;
  final bool isLocked;
  final double size;
  final int? levelNumber;
  final bool isExam;
  final bool isLeft;
  final int? sequentialModuleNumber;

  const IslandNodeWidget({
    super.key,
    required this.imageAsset,
    required this.onTap,
    this.isLocked = false,
    this.size = 180,
    this.levelNumber,
    this.isExam = false,
    this.isLeft = true,
    this.sequentialModuleNumber,
  });

  @override
  Widget build(BuildContext context) {
    // Independent positioning logic per orientation and level
    double topOffset = size * 0.25;
    double? leftOffset;
    double? rightOffset;

    final int level = levelNumber ?? 1;
    final int normalizedLevel = ((level - 1) % 3) + 1;

    if (isExam) {
      topOffset = size * 0.3; // Was 0.3, increased to move base lower
    } else {
      // Level-Specific Fine Tuning
      if (normalizedLevel == 1) {
        topOffset = size * 0.2;
        if (isLeft) {
          rightOffset = size * 0.46;
          topOffset = size * 0.22;
        } else {
          leftOffset = size * 0.47;
          topOffset =size *0.27;
        }
      } 
      else if (normalizedLevel == 2) {
        topOffset = size * 0.29;
        if (isLeft) {
          rightOffset = size * 0.45;
          topOffset = size * 0.2;
        } else {
          leftOffset = size * 0.40;
          topOffset = size *0.2;
        }
      } 
      else {
        topOffset = size * 0.25;
        if (isLeft) {
          rightOffset = size * 0.4;

        } else {
          leftOffset = size * 0.4;

        }
      }
    }

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.7 : 1.0,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _IslandImage(assetPath: imageAsset, size: size),
              
              // Level Badge
              if (sequentialModuleNumber != null || isExam)
                Positioned(
                  top: topOffset,
                  left: leftOffset,
                  right: rightOffset,
                  child: _LevelButtonBadge(
                    displayNumber: sequentialModuleNumber ?? 0,
                    isExam: isExam,
                    levelContext: level,
                    isLocked: isLocked,
                  ),
                ),

              // Visual marker for locked state - optional if using locklev.png
              if (isLocked && !isExam)
                Positioned(
                  bottom: size * 0.1,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelButtonBadge extends StatelessWidget {
  final int displayNumber;
  final bool isExam;
  final int levelContext;
  final bool isLocked;

  const _LevelButtonBadge({
    required this.displayNumber,
    this.isExam = false,
    required this.levelContext,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    // Correct paths confirmed by list_files
    const String lockedPath = 'assets/map/locklev.png';
    const String examPath = 'assets/map/levE.png';
    const String examBasePath = 'assets/map/levpoint.png';
    const String modulePath = 'assets/map/levelbutton.png';
    
    if (isLocked && !isExam) {
      return Image.asset(
        lockedPath,
        width: 58, // Smaller
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.lock, color: Colors.grey),
      );
    }

    if (isExam) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Base for the exam - Always shown
          Image.asset(
            examBasePath,
            width: 100, // Smaller
            height: 75,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          // Exam button or lock on top
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: isLocked 
              ? Image.asset(
                  lockedPath,
                  width: 58,
                  height: 50,
                  fit: BoxFit.contain,
                )
              : Image.asset(
                  examPath,
                  width: 58,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.star, color: Colors.blue),
                ),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          modulePath,
          width: 58, // Smaller
          height: 52,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ERROR: Failed to load module badge: $modulePath');
            return const Icon(Icons.circle, color: Colors.blue);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '$displayNumber',
            style: const TextStyle(
              color: Color(0xFF01172E),
              fontSize: 18, // Slightly smaller font
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _IslandImage extends StatelessWidget {
  final String assetPath;
  final double size;

  const _IslandImage({required this.assetPath, required this.size});

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallbackImage(size),
      );
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallbackImage(size),
    );
  }

  Widget _fallbackImage(double size) {
    final fallback = AppAssets.fallbackForIslandAsset(assetPath);
    if (fallback == assetPath) {
      return SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.landscape, size: 48),
      );
    }

    return Image.asset(
      fallback,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.landscape, size: 48),
      ),
    );
  }
}

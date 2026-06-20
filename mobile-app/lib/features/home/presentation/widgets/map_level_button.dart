import 'package:flutter/material.dart';
import 'package:learnova/core/constants/app_assets.dart';
import 'package:learnova/core/theme/app_colors.dart';

class MapLevelButton extends StatelessWidget {
  final double top;
  final double left;
  final String levelNumber;
  final bool isLocked;
  final VoidCallback onTap;
  final double buttonScale;

  const MapLevelButton({
    super.key,
    required this.top,
    required this.left,
    required this.levelNumber,
    this.isLocked = false,
    required this.onTap,
    this.buttonScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isExamNode = levelNumber.toUpperCase() == 'E';

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: ColorManager.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            isLocked
                ? 'assets/map/locklev.png'
                : isExamNode
                    ? 'assets/map/levE.png'
                    : AppAssets.mapLevel(int.tryParse(levelNumber) ?? 1),
            width: 65 * buttonScale,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:learnova/core/theme/app_colors_theme.dart';
import 'package:learnova/core/widgets/app_background.dart';

class SpaceScaffold extends StatelessWidget {
  final Widget child;
  final List<String>? topWavePaths;
  final List<String>? bottomWavePaths;
  final Color? topWavesColor;
  final Color? bottomWavesColor;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  const SpaceScaffold({
    super.key,
    required this.child,
    this.topWavePaths,
    this.bottomWavePaths,
    this.topWavesColor,
    this.bottomWavesColor,
    this.extendBodyBehindAppBar = false,
    this.appBar,
    this.resizeToAvoidBottomInset = false,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.isDark ? colors.background : Colors.transparent,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: Stack(
        children: [
          // 1. Background Layer — space image (dark) or gradient (light)
          const Positioned.fill(
            child: AppBackground(),
          ),

          // 2. Top Wave Layers
          if (topWavePaths != null)
            ...topWavePaths!.map(
              (path) => Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SvgPicture.asset(
                  path,
                  width: size.width,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  colorFilter: topWavesColor != null
                      ? ColorFilter.mode(topWavesColor!, BlendMode.srcIn)
                      : null,
                ),
              ),
            ),

          // 3. Bottom Wave Layers
          if (bottomWavePaths != null)
            ...bottomWavePaths!.map(
              (path) => Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SvgPicture.asset(
                  path,
                  width: size.width,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  colorFilter: bottomWavesColor != null
                      ? ColorFilter.mode(bottomWavesColor!, BlendMode.srcIn)
                      : null,
                ),
              ),
            ),

          // 4. Content Layer
          child,
        ],
      ),
    );
  }
}

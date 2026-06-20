import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';

class HexAvatarPanel extends StatelessWidget {
  const HexAvatarPanel({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.borderColor = ColorManager.white,
    this.borderWidth = 2,
    this.imageInset = 3,
    this.glowColor,
    this.glowBlurSigma = 8,
    this.glowStrokeExtra = 2,
    this.apexX = 0.5,
    this.topY = 0,
    this.upperY = 0.25,
    this.lowerY = 0.75,
    this.bottomY = 1,
  });

  final double width;
  final double height;
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final double imageInset;
  final Color? glowColor;
  final double glowBlurSigma;
  final double glowStrokeExtra;
  final double apexX;
  final double topY;
  final double upperY;
  final double lowerY;
  final double bottomY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Disable unoptimized CustomPaint MaskFilter.blur glow
          // if (glowColor != null)
          //   CustomPaint(
          //     painter: _HexBorderPainter(
          //       color: glowColor!,
          //       strokeWidth: borderWidth + glowStrokeExtra,
          //       blurSigma: glowBlurSigma,
          //       apexX: apexX,
          //       topY: topY,
          //       upperY: upperY,
          //       lowerY: lowerY,
          //       bottomY: bottomY,
          //     ),
          //   ),
          CustomPaint(
            painter: _HexBorderPainter(
              color: borderColor,
              strokeWidth: borderWidth,
              apexX: apexX,
              topY: topY,
              upperY: upperY,
              lowerY: lowerY,
              bottomY: bottomY,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(imageInset),
            child: ClipPath(
              clipper: _HexagonClipper(
                apexX: apexX,
                topY: topY,
                upperY: upperY,
                lowerY: lowerY,
                bottomY: bottomY,
              ),
              clipBehavior: Clip.hardEdge,
              child: RepaintBoundary(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexBorderPainter extends CustomPainter {
  const _HexBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.apexX,
    required this.topY,
    required this.upperY,
    required this.lowerY,
    required this.bottomY,
  });

  final Color color;
  final double strokeWidth;
  final double apexX;
  final double topY;
  final double upperY;
  final double lowerY;
  final double bottomY;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(
      _HexagonClipper(
        apexX: apexX,
        topY: topY,
        upperY: upperY,
        lowerY: lowerY,
        bottomY: bottomY,
      ).getClip(size),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HexBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.apexX != apexX ||
        oldDelegate.topY != topY ||
        oldDelegate.upperY != upperY ||
        oldDelegate.lowerY != lowerY ||
        oldDelegate.bottomY != bottomY;
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper({
    required this.apexX,
    required this.topY,
    required this.upperY,
    required this.lowerY,
    required this.bottomY,
  });

  final double apexX;
  final double topY;
  final double upperY;
  final double lowerY;
  final double bottomY;

  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(size.width * apexX, size.height * topY);
    path.lineTo(size.width, size.height * upperY);
    path.lineTo(size.width, size.height * lowerY);
    path.lineTo(size.width * apexX, size.height * bottomY);
    path.lineTo(0, size.height * lowerY);
    path.lineTo(0, size.height * upperY);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

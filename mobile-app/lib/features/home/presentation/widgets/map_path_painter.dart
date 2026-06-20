import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';

class MapPathPainter extends CustomPainter {
  final double scaleX;
  final double scaleY;

  const MapPathPainter({required this.scaleX, required this.scaleY});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint whitePaint = Paint()
      ..color = ColorManager.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint darkPaint = Paint()
      ..color = ColorManager.uiInkDark
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // World 1
    _drawDashedPath(canvas, _buildW1Path1(), whitePaint);
    _drawDashedPath(canvas, _buildW1Path2(), whitePaint);
    _drawDashedPath(canvas, _buildW1Path3(), whitePaint);
    _drawDashedPath(canvas, _buildW1Path4(), darkPaint);

    // World 2
    _drawDashedPath(canvas, _buildW2Path1(), darkPaint);
    _drawDashedPath(canvas, _buildW2Path2(), whitePaint);
    _drawDashedPath(canvas, _buildW2Path3(), whitePaint);
    _drawDashedPath(canvas, _buildW2Path4(), whitePaint);

    // World 3
    _drawDashedPath(canvas, _buildW3Path1(), whitePaint);
    _drawDashedPath(canvas, _buildW3Path2(), whitePaint);
    _drawDashedPath(canvas, _buildW3Path3(), whitePaint);
  }

  // ── World 1 Paths ──────────────────────────────────────────────────────────

  Path _buildW1Path1() {
    return Path()
      ..moveTo(266.5 * scaleX, 207 * scaleY)
      ..cubicTo(270.334 * scaleX, 212.167 * scaleY, 288.209 * scaleX,
          240.7 * scaleY, 266.5 * scaleX, 267 * scaleY)
      ..cubicTo(240.501 * scaleX, 298.5 * scaleY, 127 * scaleX, 279 * scaleY,
          141.5 * scaleX, 325 * scaleY);
  }

  Path _buildW1Path2() {
    return Path()
      ..moveTo(194.5 * scaleX, 388 * scaleY)
      ..cubicTo(210.833 * scaleX, 397 * scaleY, 245.5 * scaleX, 420.7 * scaleY,
          253.5 * scaleX, 443.5 * scaleY)
      ..cubicTo(263.5 * scaleX, 472 * scaleY, 203.5 * scaleX, 512.5 * scaleY,
          176 * scaleX, 556 * scaleY);
  }

  Path _buildW1Path3() {
    return Path()
      ..moveTo(117 * scaleX, 628.5 * scaleY)
      ..cubicTo(105 * scaleX, 634.5 * scaleY, 105.225 * scaleX, 649.07 * scaleY,
          128 * scaleX, 661 * scaleY)
      ..cubicTo(159.5 * scaleX, 677.5 * scaleY, 196 * scaleX, 676 * scaleY,
          230 * scaleX, 692 * scaleY);
  }

  Path _buildW1Path4() {
    return Path()
      ..moveTo(290 * scaleX, 763 * scaleY)
      ..cubicTo(294 * scaleX, 770 * scaleY, 296 * scaleX, 778 * scaleY,
          300 * scaleX, 782 * scaleY)
      ..cubicTo(305 * scaleX, 787 * scaleY, 298.5 * scaleX, 814 * scaleY,
          307.5 * scaleX, 815 * scaleY)
      ..cubicTo(316.5 * scaleX, 816 * scaleY, 320.5 * scaleX, 824 * scaleY,
          319.5 * scaleX, 837.5 * scaleY)
      ..cubicTo(318.5 * scaleX, 851 * scaleY, 314.5 * scaleX, 874 * scaleY,
          327 * scaleX, 876.5 * scaleY)
      ..cubicTo(339.5 * scaleX, 879 * scaleY, 329.5 * scaleX, 906.5 * scaleY,
          338.5 * scaleX, 909.5 * scaleY)
      ..cubicTo(347.5 * scaleX, 912.5 * scaleY, 353.5 * scaleX, 913 * scaleY,
          353.5 * scaleX, 961 * scaleY);
  }

  // ── World 2 Paths ──────────────────────────────────────────────────────────

  Path _buildW2Path1() {
    return Path()
      ..moveTo(320.5 * scaleX, 1027.72 * scaleY)
      ..cubicTo(309 * scaleX, 1033.89 * scaleY, 301.1 * scaleX,
          1037.92 * scaleY, 251.5 * scaleX, 1038.72 * scaleY)
      ..cubicTo(189.5 * scaleX, 1039.72 * scaleY, 190.5 * scaleX,
          1012.72 * scaleY, 124.5 * scaleX, 1038.72 * scaleY);
  }

  Path _buildW2Path2() {
    return Path()
      ..moveTo(90.5 * scaleX, 1098.22 * scaleY)
      ..cubicTo(83.6667 * scaleX, 1130.05 * scaleY, 87.5 * scaleX,
          1201.52 * scaleY, 157.5 * scaleX, 1232.72 * scaleY);
  }

  Path _buildW2Path3() {
    return Path()
      ..moveTo(255.5 * scaleX, 1255 * scaleY)
      ..cubicTo(280.167 * scaleX, 1255 * scaleY, 328 * scaleX, 1263.2 * scaleY,
          322 * scaleX, 1296 * scaleY)
      ..cubicTo(319.348 * scaleX, 1310.5 * scaleY, 316 * scaleX,
          1325.67 * scaleY, 315.5 * scaleX, 1334 * scaleY);
  }

  Path _buildW2Path4() {
    return Path()
      ..moveTo(295 * scaleX, 1424 * scaleY)
      ..cubicTo(287.5 * scaleX, 1454 * scaleY, 261.634 * scaleX,
          1490.18 * scaleY, 235 * scaleX, 1499 * scaleY)
      ..cubicTo(158 * scaleX, 1524.5 * scaleY, 193.5 * scaleX, 1499 * scaleY,
          148 * scaleX, 1576.09 * scaleY);
  }

  // ── World 3 Paths ──────────────────────────────────────────────────────────

  Path _buildW3Path1() {
    return Path()
      ..moveTo(119 * scaleX, 1644 * scaleY)
      ..cubicTo(111.5 * scaleX, 1657.17 * scaleY, 107.8 * scaleX,
          1683.3 * scaleY, 153 * scaleX, 1682.5 * scaleY)
      ..cubicTo(198.2 * scaleX, 1681.7 * scaleY, 240.5 * scaleX,
          1687.17 * scaleY, 256 * scaleX, 1690 * scaleY);
  }

  Path _buildW3Path2() {
    return Path()
      ..moveTo(345.5 * scaleX, 1712 * scaleY)
      ..cubicTo(368.167 * scaleX, 1725.17 * scaleY, 373.6 * scaleX,
          1761.2 * scaleY, 214 * scaleX, 1800 * scaleY);
  }

  Path _buildW3Path3() {
    return Path()
      ..moveTo(123 * scaleX, 1827.5 * scaleY)
      ..cubicTo(66.8334 * scaleX, 1847.83 * scaleY, 29.0002 * scaleX,
          1888.5 * scaleY, 148.5 * scaleX, 1964 * scaleY);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashLength = 12.0;
    const double gapLength = 8.0;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPathPainter old) =>
      old.scaleX != scaleX || old.scaleY != scaleY;
}

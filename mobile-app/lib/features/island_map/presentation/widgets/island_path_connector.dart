import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:learnova/core/theme/app_colors.dart';

class IslandPathConnector extends CustomPainter {
  final List<Offset> points;

  IslandPathConnector({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Paint paint = Paint()
      ..color = ColorManager.white.withValues(alpha: 0.9)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Draw curved lines between points
      // Control points are adjusted to create a nice zig-zag curve
      final double midY = (p1.dy + p2.dy) / 2;
      
      // Control points for a smoother bezier curve
      path.cubicTo(
        p1.dx,
        midY,
        p2.dx,
        midY,
        p2.dx,
        p2.dy,
      );
    }

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashLength = 10.0;
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
  bool shouldRepaint(covariant IslandPathConnector oldDelegate) {
    return true; // Simple approach, could optimize to check if points changed
  }
}

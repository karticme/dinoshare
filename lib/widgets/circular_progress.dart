import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class DCircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const DCircularProgress({
    super.key,
    required this.value,
    required this.size,
    this.strokeWidth = 4,
    this.color,
    this.backgroundColor,
  }) : assert(value >= 0 && value <= 100, 'value must be between 0 and 100');

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final double normalized = (value / 100).clamp(0.0, 1.0);
    final double resolvedStroke = math.min(strokeWidth, size / 2);

    return Semantics(
      label: 'Progress',
      value: '${value.round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CircularProgressPainter(
            progress: normalized,
            strokeWidth: resolvedStroke,
            color: color ?? theme.colors.primary,
            backgroundColor: backgroundColor ?? theme.colors.secondary,
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final progressPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, backgroundPaint);
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

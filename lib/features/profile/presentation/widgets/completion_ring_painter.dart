/// Custom painter that draws a circular progress arc for profile completion.
///
/// Used by [ProfileHero] to wrap the avatar in a gradient arc
/// from primary (orange) to secondary (teal).
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Paints a circular progress ring with a gradient stroke.
///
/// [progress] is a 0.0-1.0 value. The background track uses [AppColors.border],
/// and the filled arc uses a sweep gradient from primary to secondary.
class CompletionRingPainter extends CustomPainter {
  const CompletionRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  /// Completion fraction, 0.0 to 1.0.
  final double progress;

  /// Width of the ring stroke in logical pixels.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = (size.shortestSide - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: -1.5707963267948966, // -pi / 2
          endAngle: 4.71238898038469, // 3 * pi / 2
          colors: [AppColors.primary, AppColors.secondary],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

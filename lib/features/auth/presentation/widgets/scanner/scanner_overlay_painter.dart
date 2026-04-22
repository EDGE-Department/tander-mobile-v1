import 'dart:math';
import 'package:flutter/material.dart';
import 'document_edge_detector.dart';

class ScannerOverlayPainter extends CustomPainter {
  final DetectedEdge? detectedEdge;
  final Size imageSize;
  final bool isStable;
  final Orientation cameraOrientation;
  final double animationValue;

  static const Color orangeColor = Color(0xFFE86035);
  static const Color tealColor = Color(0xFF5BBFB3);

  ScannerOverlayPainter({
    this.detectedEdge,
    required this.imageSize,
    required this.isStable,
    required this.cameraOrientation,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Camera image is rotated 90° on Android - swap dimensions for scaling
    final bool isRotated = imageSize.width > imageSize.height;

    final double scaleX;
    final double scaleY;

    if (isRotated) {
      // Camera in landscape, screen in portrait - need to rotate coordinates
      scaleX = size.width / imageSize.height;
      scaleY = size.height / imageSize.width;
    } else {
      scaleX = size.width / imageSize.width;
      scaleY = size.height / imageSize.height;
    }

    if (detectedEdge != null) {
      // Edge detected - draw the tracked document outline
      _drawTrackedDocument(canvas, size, scaleX, scaleY, isRotated);
    }
  }

  void _drawTrackedDocument(Canvas canvas, Size size, double scaleX, double scaleY, bool isRotated) {
    // Map detected corner points to screen coordinates
    // When camera is rotated 90° CW: screenX = imgY, screenY = imgWidth - imgX
    Offset transformPoint(Point<double> p) {
      if (isRotated) {
        return Offset(p.y * scaleX, (imageSize.width - p.x) * scaleY);
      } else {
        return Offset(p.x * scaleX, p.y * scaleY);
      }
    }

    final topLeft = transformPoint(detectedEdge!.topLeft);
    final topRight = transformPoint(detectedEdge!.topRight);
    final bottomRight = transformPoint(detectedEdge!.bottomRight);
    final bottomLeft = transformPoint(detectedEdge!.bottomLeft);

    final corners = [topLeft, topRight, bottomRight, bottomLeft];

    // Create path connecting the corners
    final path = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    // Edge color
    final edgeColor = isStable ? tealColor : orangeColor;

    // Draw subtle glow around edges
    final glowPaint = Paint()
      ..color = edgeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    // Draw edge lines
    final edgePaint = Paint()
      ..color = edgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, edgePaint);

    // Draw corner markers
    for (final corner in corners) {
      // Outer glow
      canvas.drawCircle(
        corner,
        16,
        Paint()
          ..color = edgeColor.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // White filled circle
      canvas.drawCircle(
        corner,
        12,
        Paint()..color = Colors.white,
      );

      // Colored ring
      canvas.drawCircle(
        corner,
        12,
        Paint()
          ..color = edgeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      // Center dot
      canvas.drawCircle(
        corner,
        4,
        Paint()..color = edgeColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.detectedEdge != detectedEdge ||
           oldDelegate.imageSize != imageSize ||
           oldDelegate.isStable != isStable ||
           oldDelegate.animationValue != animationValue;
  }
}

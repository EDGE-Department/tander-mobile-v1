import 'package:flutter/material.dart';

/// Detection sub-state for the scanner overlay.
enum DetectionState {
  searching,
  detected,
  confirming,
  stable,
}

/// Scan phase for the scanner overlay.
enum ScanPhase {
  initializing,
  scanning,
  capturing,
  processing,
  retrying,
  timeout,
  error,
}

/// CamScanner-inspired overlay with a guide frame that changes color
/// based on detection confidence:
///
/// - **Searching** (white, pulsing): No ID detected yet
/// - **Detected** (blue, solid): ID text found — keep holding
/// - **Confirming** (blue, bright): Confirming ID — hold steady
/// - **Stable** (green, glowing): Capturing now
///
/// The guide frame is always ID-card shaped (1.586:1 ratio) and centered.
/// Unlike edge-tracking overlays, this approach gives consistent, smooth
/// visual feedback without frame-to-frame jitter.
class AutoTrackOverlayPainter extends CustomPainter {
  final DetectionState detectionState;
  final ScanPhase scanPhase;
  final double pulseValue;
  final Size screenSize;
  final double confidenceLevel;
  final double reservedTopInset;
  final double reservedBottomInset;

  AutoTrackOverlayPainter({
    required this.detectionState,
    required this.scanPhase,
    required this.pulseValue,
    required this.screenSize,
    this.confidenceLevel = 0.0,
    this.reservedTopInset = 0,
    this.reservedBottomInset = 0,
  });

  static const _scannerBlue = Color(0xFF2979FF);
  static const _stableGreen = Color(0xFF00C853);

  @override
  void paint(Canvas canvas, Size size) {
    // Tall vertical rectangle — fills the space below the header.
    final marginH = size.width * 0.04;
    final headerClearance = reservedTopInset + 16;
    final marginBottom = reservedBottomInset + 16;
    final frameWidth = size.width - marginH * 2;
    final frameHeight = (size.height - headerClearance - marginBottom).clamp(0.0, size.height).toDouble();

    final frameRect = Rect.fromLTWH(
      marginH,
      headerClearance,
      frameWidth,
      frameHeight,
    );

    // Dark scrim with rounded-rect cutout.
    _drawScrim(canvas, size, frameRect);

    // Frame border + corners based on state.
    _drawFrame(canvas, frameRect);

    // Inner glow when detected/stable.
    if (detectionState == DetectionState.stable) {
      _drawInnerGlow(canvas, frameRect, _stableGreen);
    } else if (detectionState == DetectionState.detected ||
        detectionState == DetectionState.confirming) {
      _drawInnerGlow(canvas, frameRect, _scannerBlue);
    }
  }

  void _drawScrim(Canvas canvas, Size size, Rect frameRect) {
    const cornerRadius = 20.0;
    final scrimPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        frameRect,
        const Radius.circular(cornerRadius),
      ));
    scrimPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(
      scrimPath,
      Paint()..color = const Color(0xAA000000),
    );
  }

  void _drawFrame(Canvas canvas, Rect rect) {
    const cornerRadius = 20.0;
    const cornerSize = 36.0;
    const cornerStroke = 3.5;

    final Color borderColor;
    final Color cornerColor;
    final double borderStroke;

    switch (detectionState) {
      case DetectionState.searching:
        final pulse = 0.20 + pulseValue * 0.15;
        borderColor = Colors.white.withValues(alpha: pulse);
        cornerColor = _scannerBlue.withValues(alpha: pulse + 0.1);
        borderStroke = 1.0;
      case DetectionState.detected:
        borderColor = _scannerBlue.withValues(alpha: 0.6);
        cornerColor = _scannerBlue;
        borderStroke = 2.0;
      case DetectionState.confirming:
        borderColor = _scannerBlue.withValues(alpha: 0.85);
        cornerColor = _scannerBlue;
        borderStroke = 2.5;
      case DetectionState.stable:
        borderColor = _stableGreen;
        cornerColor = _stableGreen;
        borderStroke = 3.0;
    }

    // Thin full border.
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderStroke,
    );

    // Bold corner brackets.
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStroke
      ..strokeCap = StrokeCap.round;

    const cs = cornerSize;
    const r = cornerRadius;

    // Top-left.
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cs)
        ..lineTo(rect.left, rect.top + r)
        ..arcToPoint(Offset(rect.left + r, rect.top),
            radius: const Radius.circular(r))
        ..lineTo(rect.left + cs, rect.top),
      cornerPaint,
    );
    // Top-right.
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cs, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + r),
            radius: const Radius.circular(r))
        ..lineTo(rect.right, rect.top + cs),
      cornerPaint,
    );
    // Bottom-right.
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - cs)
        ..lineTo(rect.right, rect.bottom - r)
        ..arcToPoint(Offset(rect.right - r, rect.bottom),
            radius: const Radius.circular(r))
        ..lineTo(rect.right - cs, rect.bottom),
      cornerPaint,
    );
    // Bottom-left.
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + cs, rect.bottom)
        ..lineTo(rect.left + r, rect.bottom)
        ..arcToPoint(Offset(rect.left, rect.bottom - r),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(rect.left, rect.bottom - cs),
      cornerPaint,
    );

    // Outer glow on corners when detected/stable.
    if (detectionState != DetectionState.searching) {
      final glowPaint = Paint()
        ..color = cornerColor.withValues(alpha: 0.15 + pulseValue * 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // Simplified glow — just the full rounded rect.
      canvas.drawRRect(rrect, glowPaint);
    }
  }

  void _drawInnerGlow(Canvas canvas, Rect rect, Color color) {
    final alpha = detectionState == DetectionState.stable
        ? 0.06 + pulseValue * 0.04
        : 0.04;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(AutoTrackOverlayPainter old) {
    return old.detectionState != detectionState ||
        old.scanPhase != scanPhase ||
        old.pulseValue != pulseValue ||
        old.confidenceLevel != confidenceLevel;
  }
}

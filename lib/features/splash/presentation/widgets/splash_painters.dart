import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── Pulse ring ──────────────────────────────────────────────────────────────

/// Expanding + fading pulse ring that starts at 110x110 and scales outward.
///
/// Replica of the web's splash-ring-1 / splash-ring-2 CSS animations.
class SplashPulseRing extends StatelessWidget {
  const SplashPulseRing({
    super.key,
    required this.controller,
    required this.borderWidth,
    required this.borderColor,
    required this.maxScale,
    required this.startOpacity,
    required this.phaseOffset,
  });

  final AnimationController controller;
  final double borderWidth;
  final Color borderColor;
  final double maxScale;
  final double startOpacity;
  final double phaseOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final progress = (controller.value + phaseOffset) % 1.0;
        final scale = 1.0 + (maxScale - 1.0) * progress;
        final opacity = startOpacity * (1.0 - progress);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor.withValues(alpha: opacity.clamp(0.0, 1.0)),
                width: borderWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Constellation painter ───────────────────────────────────────────────────

/// Exact replica of web LoginConstellationSVG rendered via CustomPainter.
///
/// Uses the web's 1200x900 viewBox with "cover" (xMidYMid slice) mapping.
/// Includes: starfield background, dashed constellation edges with shimmer,
/// photon dots traveling along edges, star nodes with pulse/glow, and
/// diffraction spikes on core stars (0, 11, 16).
class SplashConstellationPainter extends CustomPainter {
  SplashConstellationPainter(this.time);
  final double time;

  // Star nodes from login-constellation.tsx (1200x900 coordinate space).
  static const _nodes = <List<double>>[
    [600, 450, 4.5], // 0  hub  #FFF6EE
    [600, 320, 2.0], // 1       #E0F2FE
    [600, 580, 2.0], // 2       #FEF3C7
    [470, 450, 2.2], // 3       #FFF
    [730, 450, 2.2], // 4       #FFF
    [510, 360, 1.8], // 5       #FFF
    [690, 360, 1.8], // 6       #FFF
    [510, 540, 1.8], // 7       #FFF
    [690, 540, 1.8], // 8       #FFF
    [400, 300, 2.5], // 9       #F07040
    [300, 330, 2.0], // 10      #F07040
    [240, 450, 2.8], // 11      #F07040
    [300, 570, 2.0], // 12      #F07040
    [400, 600, 2.5], // 13      #F07040
    [800, 300, 2.5], // 14      #0F9D94
    [900, 330, 2.0], // 15      #0F9D94
    [960, 450, 2.8], // 16      #0F9D94
    [900, 570, 2.0], // 17      #0F9D94
    [800, 600, 2.5], // 18      #0F9D94
  ];

  static const _nodeColors = <int>[
    0xFFFFF6EE,
    0xFFE0F2FE,
    0xFFFEF3C7,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFFFFFFF,
    0xFFF07040,
    0xFFF07040,
    0xFFF07040,
    0xFFF07040,
    0xFFF07040,
    0xFF0F9D94,
    0xFF0F9D94,
    0xFF0F9D94,
    0xFF0F9D94,
    0xFF0F9D94,
  ];

  static const _nodeDelays = <int>[
    0,
    200,
    400,
    600,
    800,
    300,
    500,
    700,
    900,
    150,
    450,
    750,
    1050,
    1350,
    150,
    450,
    750,
    1050,
    1350,
  ];

  static const _edges = <List<int>>[
    [0, 1],
    [0, 2],
    [0, 3],
    [0, 4],
    [0, 5],
    [0, 6],
    [0, 7],
    [0, 8],
    [1, 9],
    [9, 10],
    [10, 11],
    [11, 12],
    [12, 13],
    [13, 2],
    [1, 14],
    [14, 15],
    [15, 16],
    [16, 17],
    [17, 18],
    [18, 2],
  ];

  /// Core stars with diffraction spikes: hub (0), left anchor (11), right (16).
  static const _spikeStars = {0, 11, 16};

  /// Seeded starfield (80 background stars).
  static final _starfield = _generateStarfield();

  static List<List<double>> _generateStarfield() {
    final rng = math.Random(42);
    return List.generate(80, (_) {
      final isLarge = rng.nextDouble() > 0.8;
      return [
        rng.nextDouble() * 1200,
        rng.nextDouble() * 900,
        (isLarge ? 0.8 : 0.4) * 1.2,
        (0.1 + rng.nextDouble() * 0.4) * 1.5,
        rng.nextDouble() * 5000,
        4.0 + rng.nextDouble() * 6.0,
      ];
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // "cover" viewport mapping: scale 1200x900 to fill canvas, centered.
    final scaleX = size.width / 1200;
    final scaleY = size.height / 900;
    final scale = math.max(scaleX, scaleY);
    final offsetX = (size.width - 1200 * scale) / 2;
    final offsetY = (size.height - 900 * scale) / 2;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    final t = time;
    _paintStarfield(canvas, t);
    _paintEdges(canvas, t);
    _paintPhotons(canvas, t);
    _paintNodes(canvas, t);

    canvas.restore();
  }

  void _paintStarfield(Canvas canvas, double t) {
    final paint = Paint();
    for (final star in _starfield) {
      final delayPhase = star[4] / 15000.0;
      final dur = star[5];
      final phase = ((t * 15.0 / dur) + delayPhase) % 1.0;
      final twinkle = 0.2 + 0.5 * ((math.sin(phase * math.pi * 2) + 1) / 2);
      paint.color = Color.fromRGBO(255, 255, 255, twinkle * star[3]);
      canvas.drawCircle(Offset(star[0], star[1]), star[2], paint);
    }
  }

  void _paintEdges(Canvas canvas, double t) {
    for (int i = 0; i < _edges.length; i++) {
      final from = _nodes[_edges[i][0]];
      final to = _nodes[_edges[i][1]];
      final phase = ((t * 15.0 / 5.0) + i * 0.2 / 5.0) % 1.0;
      final shimmer = 0.2 + 0.3 * ((math.sin(phase * math.pi * 2) + 1) / 2);

      final paint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, shimmer * 0.35)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      // Dashed line (1 on, 4 off)
      final dx = to[0] - from[0];
      final dy = to[1] - from[1];
      final length = math.sqrt(dx * dx + dy * dy);
      final nx = dx / length;
      final ny = dy / length;
      const dashLen = 1.0;
      const gapLen = 4.0;
      double d = 0;
      while (d < length) {
        final end = math.min(d + dashLen, length);
        canvas.drawLine(
          Offset(from[0] + nx * d, from[1] + ny * d),
          Offset(from[0] + nx * end, from[1] + ny * end),
          paint,
        );
        d += dashLen + gapLen;
      }
    }
  }

  void _paintPhotons(Canvas canvas, double t) {
    for (int i = 0; i < _edges.length; i++) {
      final from = _nodes[_edges[i][0]];
      final to = _nodes[_edges[i][1]];
      final dur = 4.0 + (i % 3).toDouble();
      final delay = i * 0.8;
      final phase = ((t * 15.0 + delay) / dur) % 1.0;

      final pos = Offset(
        from[0] + (to[0] - from[0]) * phase,
        from[1] + (to[1] - from[1]) * phase,
      );

      final fade =
          (phase / 0.1).clamp(0.0, 1.0) * ((1.0 - phase) / 0.1).clamp(0.0, 1.0);
      if (fade < 0.02) continue;

      canvas.drawCircle(
        pos,
        4,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, fade * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        pos,
        1.5,
        Paint()..color = Color.fromRGBO(255, 255, 255, fade * 0.8),
      );
    }
  }

  void _paintNodes(Canvas canvas, double t) {
    for (int i = 0; i < _nodes.length; i++) {
      final node = _nodes[i];
      final color = Color(_nodeColors[i]);
      final delay = _nodeDelays[i] / 1000.0;
      final dur = 2.5 + (i % 3).toDouble();
      final phase = ((t * 15.0 + delay) / dur) % 1.0;

      final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
      final scaleFactor = 1.0 + 0.15 * pulse;
      final opacityFactor = 0.6 + 0.4 * pulse;

      final cx = node[0];
      final cy = node[1];
      final r = node[2];

      // Diffraction spikes for core stars
      if (_spikeStars.contains(i)) {
        final armLen = r * 10;
        final spikePaint = Paint()
          ..color = color.withValues(alpha: 0.45)
          ..strokeWidth = 0.5;
        canvas.drawLine(
          Offset(cx - armLen, cy),
          Offset(cx + armLen, cy),
          spikePaint,
        );
        canvas.drawLine(
          Offset(cx, cy - armLen),
          Offset(cx, cy + armLen),
          spikePaint,
        );
      }

      // Outer glow
      canvas.drawCircle(
        Offset(cx, cy),
        r * 2.8 * scaleFactor,
        Paint()
          ..color = color.withValues(alpha: 0.2 * opacityFactor)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Core
      canvas.drawCircle(
        Offset(cx, cy),
        r * 1.1 * scaleFactor,
        Paint()..color = color.withValues(alpha: opacityFactor),
      );

      // Hub extra bright center
      if (i == 0) {
        canvas.drawCircle(
          Offset(cx, cy),
          r * 0.5,
          Paint()
            ..color = Colors.white
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(SplashConstellationPainter old) => time != old.time;
}

// ── Film grain painter ──────────────────────────────────────────────────────

/// Random white dots approximating the web's SVG feTurbulence noise.
class SplashGrainPainter extends CustomPainter {
  const SplashGrainPainter();

  static const int _dotCount = 1200;
  static const double _minRadius = 0.2;
  static const double _maxRadius = 0.8;
  static const int _seed = 42;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(_seed);
    for (int i = 0; i < _dotCount; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * _maxRadius + _minRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

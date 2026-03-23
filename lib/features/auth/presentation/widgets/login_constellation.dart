import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated constellation background matching the web's LoginConstellationSVG.
///
/// Renders twinkling star nodes connected by dim hairlines, with a central
/// hub that pulses with a mega bloom effect. Includes breathing nebula clouds
/// (orange and teal ellipses with large blur).
class LoginConstellation extends StatefulWidget {
  const LoginConstellation({super.key});

  @override
  State<LoginConstellation> createState() => _LoginConstellationState();
}

class _LoginConstellationState extends State<LoginConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) => CustomPaint(
            painter: _ConstellationPainter(progress: _controller.value),
          ),
        ),
      ),
    );
  }
}

// Star node data (normalized 0-1 coordinates, matches web's 600x900 viewBox)
class _Star {
  const _Star(this.x, this.y, this.radius, this.phase, this.color);
  final double x;
  final double y;
  final double radius;
  final double phase; // 0-1 offset for twinkle timing
  final Color color;
}

// Edge connecting two star indices
class _Edge {
  const _Edge(this.from, this.to);
  final int from;
  final int to;
}

const _hubIndex = 7;

const _stars = <_Star>[
  _Star(0.12, 0.18, 2.5, 0.00, Color(0xE6FFA05A)), // warm orange
  _Star(0.25, 0.30, 1.8, 0.15, Color(0xBFFFFFFF)), // white
  _Star(0.10, 0.45, 3.0, 0.30, Color(0xD9FFB464)), // warm
  _Star(0.38, 0.22, 2.0, 0.08, Color(0xB3FFFFFF)), // white
  _Star(0.30, 0.48, 1.5, 0.22, Color(0x8CFFFFFF)), // dim white
  _Star(0.42, 0.38, 2.0, 0.11, Color(0xB3FFFFFF)), // white
  _Star(0.38, 0.51, 2.5, 0.19, Color(0xCCFFFFFF)), // white
  _Star(0.50, 0.51, 6.0, 0.00, Color(0xFFFFFFFF)), // hub (brightest, larger)
  _Star(0.62, 0.51, 2.5, 0.19, Color(0xCCFFFFFF)), // white
  _Star(0.58, 0.38, 2.0, 0.11, Color(0xB3FFFFFF)), // white
  _Star(0.78, 0.22, 2.0, 0.08, Color(0xD996E6E1)), // teal
  _Star(0.85, 0.43, 2.5, 0.20, Color(0xE678DCD7)), // teal
  _Star(0.77, 0.59, 3.0, 0.28, Color(0xD964D2CD)), // teal
  _Star(0.89, 0.17, 1.8, 0.13, Color(0xB3FFFFFF)), // white
  _Star(0.78, 0.71, 2.0, 0.24, Color(0x8CFFFFFF)), // dim white
  _Star(0.28, 0.10, 1.5, 0.17, Color(0x8CFFFFFF)), // dim white
  _Star(0.50, 0.08, 2.0, 0.05, Color(0xA6FFFFFF)), // white
  _Star(0.72, 0.10, 1.5, 0.25, Color(0xB396E6E1)), // teal
  _Star(0.14, 0.12, 2.0, 0.03, Color(0xB3FFB464)), // warm
  _Star(0.86, 0.12, 1.5, 0.20, Color(0xB396E6E1)), // teal
];

const _edges = <_Edge>[
  _Edge(0, 1), _Edge(1, 2), _Edge(2, 4), _Edge(0, 3),
  _Edge(3, 5), _Edge(4, 5), _Edge(5, 6), _Edge(6, 7),
  _Edge(7, 8), _Edge(8, 9), _Edge(9, 11), _Edge(10, 11),
  _Edge(11, 12), _Edge(12, 14), _Edge(10, 13),
  _Edge(18, 15), _Edge(15, 16), _Edge(16, 17), _Edge(17, 19),
  _Edge(3, 15), _Edge(16, 9), _Edge(17, 13),
];

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintNebulaClouds(canvas, size);
    _paintEdges(canvas, size);
    _paintStars(canvas, size);
    _paintHubBloom(canvas, size);
    _paintHubPulseRings(canvas, size);
  }

  void _paintNebulaClouds(Canvas canvas, Size size) {
    // Breathing opacity: slow sine wave
    final breathe = 0.6 + 0.4 * math.sin(progress * math.pi * 2 * 0.5);

    // Orange nebula cloud — top-left quadrant
    final orangePaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.06 * breathe)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.30),
        width: size.width * 0.40,
        height: size.height * 0.25,
      ),
      orangePaint,
    );

    // Teal nebula cloud — bottom-right quadrant
    final tealPaint = Paint()
      ..color = const Color(0xFF14B8A6).withValues(alpha: 0.06 * breathe)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.55),
        width: size.width * 0.38,
        height: size.height * 0.22,
      ),
      tealPaint,
    );
  }

  void _paintEdges(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (final edge in _edges) {
      final from = _stars[edge.from];
      final to = _stars[edge.to];
      canvas.drawLine(
        Offset(from.x * size.width, from.y * size.height),
        Offset(to.x * size.width, to.y * size.height),
        edgePaint,
      );
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    for (var index = 0; index < _stars.length; index++) {
      final star = _stars[index];
      final isHub = index == _hubIndex;

      final twinklePhase = ((progress + star.phase) % 1.0);
      // Brighter base: 0.35 min twinkle (up from 0.22)
      final twinkle = isHub
          ? 1.0
          : 0.35 +
              0.65 * ((math.sin(twinklePhase * math.pi * 2) + 1) / 2);

      final scaledRadius = isHub
          ? star.radius * 1.15
          : star.radius * (0.92 + 0.15 * twinkle);

      final starPaint = Paint()
        ..color = star.color.withValues(alpha: star.color.a * twinkle)
        ..maskFilter = isHub
            ? const MaskFilter.blur(BlurStyle.normal, 8.0)
            : star.radius >= 2.5
                ? const MaskFilter.blur(BlurStyle.normal, 3.5)
                : const MaskFilter.blur(BlurStyle.normal, 1.8);

      final center = Offset(star.x * size.width, star.y * size.height);
      canvas.drawCircle(center, scaledRadius, starPaint);

      // Core dot (sharper)
      final corePaint = Paint()
        ..color = star.color.withValues(alpha: star.color.a * twinkle);
      canvas.drawCircle(center, star.radius * 0.5, corePaint);
    }
  }

  void _paintHubBloom(Canvas canvas, Size size) {
    final hub = _stars[_hubIndex];
    final hubCenter = Offset(hub.x * size.width, hub.y * size.height);

    // Mega bloom: large soft glow behind hub
    final bloomPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(hubCenter, 18, bloomPaint);

    // Secondary warm bloom
    final warmBloomPaint = Paint()
      ..color = const Color(0xFFFFA05A).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(hubCenter, 26, warmBloomPaint);
  }

  void _paintHubPulseRings(Canvas canvas, Size size) {
    final hubX = _stars[_hubIndex].x * size.width;
    final hubY = _stars[_hubIndex].y * size.height;

    for (var ringIndex = 0; ringIndex < 3; ringIndex++) {
      final ringPhase =
          ((progress * (1.0 + ringIndex * 0.3) + ringIndex * 0.33) % 1.0);
      final ringRadius = 6 + ringPhase * 56;
      final ringOpacity = 0.68 * (1 - ringPhase);

      if (ringOpacity > 0.01) {
        canvas.drawCircle(
          Offset(hubX, hubY),
          ringRadius,
          Paint()
            ..color = Colors.white.withValues(alpha: ringOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * (1 - ringPhase * 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

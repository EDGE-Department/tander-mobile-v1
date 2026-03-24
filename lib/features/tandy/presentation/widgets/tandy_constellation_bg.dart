import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated constellation background for the Tandy chat.
/// Matches the web's TandyConstellationBg (light variant):
/// - Dot grid pattern
/// - Twinkling star nodes with faint connecting lines
/// - Central hub with expanding pulse rings
/// - Soft nebula clouds (orange + teal)
/// - Energy orbs traveling along edges
class TandyConstellationBg extends StatefulWidget {
  const TandyConstellationBg({super.key});

  @override
  State<TandyConstellationBg> createState() => _TandyConstellationBgState();
}

class _TandyConstellationBgState extends State<TandyConstellationBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _ConstellationPainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────

class _Star {
  const _Star(this.x, this.y, this.r, this.delay, this.color);
  final double x, y, r, delay;
  final Color color;
}

class _Edge {
  const _Edge(this.from, this.to);
  final int from, to;
}

// Normalized coordinates (0-1 range), will be scaled to canvas size
const List<_Star> _stars = [
  _Star(0.12, 0.18, 2.5, 0.0,  Color(0x61E67E22)),
  _Star(0.25, 0.30, 1.8, 0.3,  Color(0x388C6440)),
  _Star(0.10, 0.45, 3.0, 0.6,  Color(0x57D76C14)),
  _Star(0.38, 0.22, 2.0, 0.15, Color(0x338C6440)),
  _Star(0.30, 0.48, 1.5, 0.45, Color(0x298C6440)),
  _Star(0.42, 0.38, 2.0, 0.22, Color(0x388C6440)),
  _Star(0.38, 0.50, 2.5, 0.37, Color(0x52D27318)),
  _Star(0.50, 0.50, 5.0, 0.0,  Color(0x8CE67E22)), // Hub
  _Star(0.62, 0.50, 2.5, 0.37, Color(0x52D27318)),
  _Star(0.58, 0.38, 2.0, 0.22, Color(0x388C6440)),
  _Star(0.78, 0.22, 2.0, 0.15, Color(0x570F9D94)),
  _Star(0.85, 0.43, 2.5, 0.40, Color(0x610C8C87)),
  _Star(0.77, 0.59, 3.0, 0.55, Color(0x4D0A7873)),
  _Star(0.89, 0.17, 1.8, 0.25, Color(0x338C6440)),
  _Star(0.78, 0.71, 2.0, 0.47, Color(0x298C6440)),
  _Star(0.28, 0.10, 1.5, 0.35, Color(0x2E8C6440)),
  _Star(0.50, 0.08, 2.0, 0.10, Color(0x388C6440)),
  _Star(0.72, 0.10, 1.5, 0.50, Color(0x3D0F9D94)),
  _Star(0.14, 0.12, 2.0, 0.05, Color(0x47E67E22)),
  _Star(0.86, 0.12, 1.5, 0.40, Color(0x420F9D94)),
];

const List<_Edge> _edges = [
  _Edge(0, 1), _Edge(1, 2), _Edge(2, 4), _Edge(0, 3), _Edge(3, 5),
  _Edge(4, 5), _Edge(5, 6), _Edge(6, 7), _Edge(7, 8), _Edge(8, 9),
  _Edge(9, 11), _Edge(10, 11), _Edge(11, 12), _Edge(12, 14),
  _Edge(10, 13), _Edge(18, 15), _Edge(15, 16), _Edge(16, 17),
  _Edge(17, 19), _Edge(3, 15), _Edge(16, 9), _Edge(17, 13),
];

// Orb travel paths (edge indices)
const List<int> _orbEdges = [0, 3, 6, 7, 9, 11, 15, 17];

// ── Painter ───────────────────────────────────────────────────────────────

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter(this.time);
  final double time; // 0..1 repeating

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _drawDotGrid(canvas, size);
    _drawNebulae(canvas, size);
    _drawEdges(canvas, size);
    _drawOrbs(canvas, size);
    _drawStars(canvas, size);
    _drawHub(canvas, size);
  }

  Offset _starPos(int index, Size size) {
    final star = _stars[index];
    return Offset(star.x * size.width, star.y * size.height);
  }

  // Subtle dot grid
  void _drawDotGrid(Canvas canvas, Size size) {
    const spacing = 36.0;
    final paint = Paint()..color = const Color(0x09B47A1E);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  // Soft blurred nebula clouds
  void _drawNebulae(Canvas canvas, Size size) {
    final t = time * math.pi * 2;

    // Orange nebula (left side)
    final orangeOpacity = 0.04 + 0.015 * math.sin(t * 0.5);
    final orangePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(230, 126, 34, orangeOpacity.clamp(0.0, 1.0)),
          const Color(0x00E67E22),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.29, size.height * 0.36),
        radius: size.width * 0.28,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.29, size.height * 0.36),
        width: size.width * 0.55,
        height: size.height * 0.37,
      ),
      orangePaint,
    );

    // Teal nebula (right side)
    final tealOpacity = 0.03 + 0.012 * math.sin(t * 0.43 + 1.1);
    final tealPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(15, 157, 148, tealOpacity.clamp(0.0, 1.0)),
          const Color(0x000F9D94),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.74, size.height * 0.44),
        radius: size.width * 0.28,
      ));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.74, size.height * 0.44),
        width: size.width * 0.55,
        height: size.height * 0.37,
      ),
      tealPaint,
    );
  }

  // Faint connecting lines between stars
  void _drawEdges(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12A06E32)
      ..strokeWidth = 0.55
      ..style = PaintingStyle.stroke;

    for (final edge in _edges) {
      final from = _starPos(edge.from, size);
      final to = _starPos(edge.to, size);
      // Bridge edges (connected to hub at index 7) are brighter
      final isBridge = edge.from == 7 || edge.to == 7;
      if (isBridge) {
        final bridgeT = time * math.pi * 2;
        final bridgeOpacity = 0.10 + 0.08 * math.sin(bridgeT * 1.7);
        paint.color = Color.fromRGBO(230, 126, 34, bridgeOpacity.clamp(0.0, 1.0));
        paint.strokeWidth = 1.0;
      } else {
        paint.color = const Color(0x12A06E32);
        paint.strokeWidth = 0.55;
      }
      canvas.drawLine(from, to, paint);
    }
  }

  // Energy orbs traveling along edges
  void _drawOrbs(Canvas canvas, Size size) {
    for (int i = 0; i < _orbEdges.length; i++) {
      final edgeIdx = _orbEdges[i];
      final edge = _edges[edgeIdx];
      final from = _starPos(edge.from, size);
      final to = _starPos(edge.to, size);

      // Each orb has a different phase
      final orbPhase = (time + i * 0.125) % 1.0;
      final pos = Offset.lerp(from, to, orbPhase)!;

      // Fade in/out at edges
      final fadeIn = (orbPhase / 0.08).clamp(0.0, 1.0);
      final fadeOut = ((1.0 - orbPhase) / 0.08).clamp(0.0, 1.0);
      final opacity = (fadeIn * fadeOut * 0.20).clamp(0.0, 1.0);

      if (opacity > 0.01) {
        final isOrange = edgeIdx < 8;
        final color = isOrange
            ? Color.fromRGBO(230, 126, 34, opacity)
            : Color.fromRGBO(15, 157, 148, opacity);
        final glowPaint = Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(pos, 7, glowPaint);
        canvas.drawCircle(pos, 3, Paint()..color = color);
      }
    }
  }

  // Twinkling star nodes
  void _drawStars(Canvas canvas, Size size) {
    final t = time * math.pi * 2;

    for (int i = 0; i < _stars.length; i++) {
      if (i == 7) continue; // Hub drawn separately
      final star = _stars[i];
      final pos = Offset(star.x * size.width, star.y * size.height);

      // Twinkle: oscillate opacity and scale
      final phase = t + star.delay * math.pi * 4;
      final twinkle = 0.10 + 0.32 * ((math.sin(phase * 0.9) + 1) / 2);
      final scale = 0.92 + 0.15 * ((math.sin(phase * 0.9) + 1) / 2);
      final r = star.r * scale;

      // Bloom glow
      if (star.r >= 2.5) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity((twinkle * 0.5).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(pos, r * 2, glowPaint);
      }

      canvas.drawCircle(
        pos,
        r,
        Paint()..color = star.color.withOpacity(twinkle.clamp(0.0, 1.0)),
      );
    }
  }

  // Central hub with pulse rings, halos, and heartbeat
  void _drawHub(Canvas canvas, Size size) {
    final hub = Offset(size.width * 0.5, size.height * 0.5);
    final t = time * math.pi * 2;

    // Halos
    canvas.drawCircle(hub, 22, Paint()..color = const Color(0x04E67E22));
    canvas.drawCircle(hub, 13, Paint()..color = const Color(0x06E67E22));

    // Diffraction cross
    final crossOpacity = 0.12 + 0.16 * ((math.sin(t * 2.1) + 1) / 2);
    final crossPaint = Paint()
      ..color = Color.fromRGBO(230, 126, 34, crossOpacity.clamp(0.0, 1.0))
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(hub.dx - 40, hub.dy), Offset(hub.dx + 40, hub.dy), crossPaint);
    canvas.drawLine(Offset(hub.dx, hub.dy - 40), Offset(hub.dx, hub.dy + 40), crossPaint);

    // Pulse rings (3 expanding rings at different phases)
    for (int i = 0; i < 3; i++) {
      final ringPhase = (time + i * 0.33) % 1.0;
      final maxR = [62.0, 56.0, 84.0][i];
      final r = 6 + (maxR - 6) * ringPhase;
      final opacity = 0.35 * (1.0 - ringPhase);
      final strokeW = 1.5 * (1.0 - ringPhase * 0.9);
      final ringColor = i < 2
          ? Color.fromRGBO(230, 126, 34, opacity.clamp(0.0, 1.0))
          : Color.fromRGBO(15, 157, 148, opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        hub,
        r,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );
    }

    // Heartbeat core
    final heartbeat = _heartbeatScale(time);
    final coreOpacity = 0.38 + 0.24 * ((math.sin(t * 1.65) + 1) / 2);
    final corePaint = Paint()
      ..color = Color.fromRGBO(230, 126, 34, coreOpacity.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(hub, 5.5 * heartbeat, corePaint);
    canvas.drawCircle(
      hub,
      5.5 * heartbeat,
      Paint()..color = Color.fromRGBO(230, 126, 34, (coreOpacity * 0.7).clamp(0.0, 1.0)),
    );
  }

  // Web keyframes: 0%→scale(1), 14%→scale(1.72), 28%→scale(1), 44%→scale(1.38), 60-100%→scale(1)
  double _heartbeatScale(double t) {
    final phase = (t * 5.26) % 1.0; // ~3.8s period
    if (phase < 0.14) return 1.0 + 0.72 * (phase / 0.14);
    if (phase < 0.28) return 1.72 - 0.72 * ((phase - 0.14) / 0.14);
    if (phase < 0.44) return 1.0 + 0.38 * ((phase - 0.28) / 0.16);
    if (phase < 0.60) return 1.38 - 0.38 * ((phase - 0.44) / 0.16);
    return 1.0;
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) => time != oldDelegate.time;
}

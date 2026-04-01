import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated constellation for the login & forgot-password headers.
///
/// Complex pattern (stars, edges, orbs, hub, nebulae) executed at
/// low visual weight so text remains readable over the gradient.
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
      duration: const Duration(seconds: 15),
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

// ── Data ─────────────────────────────────────────────────────────────

class _Star {
  const _Star(this.x, this.y, this.radius, this.phase, this.color);
  final double x, y, radius, phase;
  final Color color;
}

class _Edge {
  const _Edge(this.from, this.to);
  final int from, to;
}

const _hubIndex = 7;

const _stars = <_Star>[
  _Star(0.12, 0.18, 2.0, 0.00, Color(0xB3FFA05A)),
  _Star(0.25, 0.30, 1.4, 0.15, Color(0x99FFFFFF)),
  _Star(0.10, 0.45, 2.2, 0.30, Color(0xA6FFB464)),
  _Star(0.38, 0.22, 1.6, 0.08, Color(0x8CFFFFFF)),
  _Star(0.30, 0.48, 1.2, 0.22, Color(0x66FFFFFF)),
  _Star(0.42, 0.38, 1.6, 0.11, Color(0x8CFFFFFF)),
  _Star(0.38, 0.51, 2.0, 0.19, Color(0x99FFFFFF)),
  _Star(0.50, 0.51, 3.5, 0.00, Color(0xCCFFFFFF)), // hub
  _Star(0.62, 0.51, 2.0, 0.19, Color(0x99FFFFFF)),
  _Star(0.58, 0.38, 1.6, 0.11, Color(0x8CFFFFFF)),
  _Star(0.78, 0.22, 1.6, 0.08, Color(0xA696E6E1)),
  _Star(0.85, 0.43, 2.0, 0.20, Color(0xB378DCD7)),
  _Star(0.77, 0.59, 2.2, 0.28, Color(0xA664D2CD)),
  _Star(0.89, 0.17, 1.4, 0.13, Color(0x8CFFFFFF)),
  _Star(0.78, 0.71, 1.6, 0.24, Color(0x66FFFFFF)),
  _Star(0.28, 0.10, 1.2, 0.17, Color(0x66FFFFFF)),
  _Star(0.50, 0.08, 1.6, 0.05, Color(0x80FFFFFF)),
  _Star(0.72, 0.10, 1.2, 0.25, Color(0x8096E6E1)),
  _Star(0.14, 0.12, 1.6, 0.03, Color(0x8CFFB464)),
  _Star(0.86, 0.12, 1.2, 0.20, Color(0x8096E6E1)),
];

const _normalEdges = <_Edge>[
  // Web-original edges only — no extra clutter
  _Edge(0, 1), _Edge(1, 2), _Edge(2, 4), _Edge(0, 3),
  _Edge(3, 5), _Edge(4, 5), _Edge(5, 6),
  _Edge(8, 9), _Edge(9, 11), _Edge(10, 11),
  _Edge(11, 12), _Edge(12, 14), _Edge(10, 13),
  _Edge(18, 15), _Edge(15, 16), _Edge(16, 17), _Edge(17, 19),
  _Edge(3, 15), _Edge(16, 9), _Edge(17, 13),
];

const _bridgeEdges = <_Edge>[_Edge(6, 7), _Edge(7, 8)];

/// Orb travel paths: [fromStarIndex, toStarIndex] — trimmed to match splash
const _orbPaths = [
  [0, 1], [6, 7], [7, 8], [10, 11],
];

// ── Painter ──────────────────────────────────────────────────────────

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({required this.progress});
  final double progress;

  static const double _yShift = 0.15;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, size.height * _yShift);
    _paintNebulae(canvas, size);
    _paintEdges(canvas, size);
    _paintBridges(canvas, size);
    _paintOrbs(canvas, size);
    _paintStars(canvas, size);
    _paintHubAccent(canvas, size);
    canvas.restore();
  }

  Offset _starPos(_Star star, Size sz) =>
      Offset(star.x * sz.width, star.y * sz.height);

  Offset _starPosAt(int index, Size sz) => _starPos(_stars[index], sz);

  // ── Very faint nebulae (atmospheric depth) ───────────────────────

  void _paintNebulae(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;

    // Warm orange — left side (synced speed)
    // Web: radialGradient stopOpacity 0.28 with heavy blur (stdDeviation=22)
    final breatheOrange = 0.6 + 0.4 * math.sin(phase * 0.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.20, size.height * 0.35),
        width: size.width * 0.50,
        height: size.height * 0.35,
      ),
      Paint()
        ..color = const Color(0xFFFF8C3C).withValues(alpha: 0.08 * breatheOrange)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    // Cool teal — right side (same speed, pi offset)
    // Web: radialGradient stopOpacity 0.22 with heavy blur
    final breatheTeal = 0.6 + 0.4 * math.sin(phase * 0.5 + math.pi);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.50),
        width: size.width * 0.40,
        height: size.height * 0.25,
      ),
      Paint()
        ..color = const Color(0xFF00C8C0).withValues(alpha: 0.05 * breatheTeal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  // ── Edges ────────────────────────────────────────────────────────

  void _paintEdges(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x18FFFFFF) // 9% alpha — more visible edges
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final edge in _normalEdges) {
      canvas.drawLine(
        _starPosAt(edge.from, size),
        _starPosAt(edge.to, size),
        paint,
      );
    }
  }

  // ── Bridge edges ─────────────────────────────────────────────────

  void _paintBridges(Canvas canvas, Size size) {
    final pulse =
        0.10 + 0.20 * ((math.sin(progress * math.pi * 2 * 1.5) + 1) / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: pulse)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (final edge in _bridgeEdges) {
      canvas.drawLine(
        _starPosAt(edge.from, size),
        _starPosAt(edge.to, size),
        paint,
      );
    }
  }

  // ── Traveling orbs (subtle energy flow) ──────────────────────────

  void _paintOrbs(Canvas canvas, Size size) {
    for (int i = 0; i < _orbPaths.length; i++) {
      final from = _starPosAt(_orbPaths[i][0], size);
      final to = _starPosAt(_orbPaths[i][1], size);
      final prog = (progress * 2.5 + i * 0.167) % 1.0;
      final pos = Offset.lerp(from, to, prog)!;

      // Smooth fade in/out
      final fadeIn = (prog / 0.10).clamp(0.0, 1.0);
      final fadeOut = ((1.0 - prog) / 0.10).clamp(0.0, 1.0);
      final fade = fadeIn * fadeOut;
      if (fade < 0.02) continue;

      final isLeft = _orbPaths[i][0] < 6;
      final isTeal = _orbPaths[i][0] >= 10;
      final orbColor = isTeal
          ? const Color(0xFFA0FFF8)
          : isLeft
              ? const Color(0xFFFFD898)
              : Colors.white;

      // Glow
      canvas.drawCircle(
        pos,
        4,
        Paint()
          ..color = orbColor.withValues(alpha: 0.12 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Core
      canvas.drawCircle(
        pos,
        1.5,
        Paint()..color = orbColor.withValues(alpha: 0.35 * fade),
      );
    }
  }

  // ── Stars ────────────────────────────────────────────────────────

  void _paintStars(Canvas canvas, Size size) {
    final animPhase = progress * math.pi * 2;

    for (var i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final isHub = i == _hubIndex;
      final center = _starPos(star, size);

      // 3-phase grouping (2pi/3 spacing) + slower twinkle (0.5x speed)
      final groupOffset = (i % 3) * 2.09;
      final phase = animPhase + groupOffset;
      final twinkle =
          0.30 + 0.55 * ((math.sin(phase * 0.5) + 1) / 2);
      final scaledRadius =
          star.radius * (0.92 + 0.16 * ((math.sin(phase * 0.5) + 1) / 2));
      final alpha = star.color.a * twinkle;

      // Soft glow for larger stars
      if (star.radius >= 1.8) {
        canvas.drawCircle(
          center,
          scaledRadius * 1.5,
          Paint()
            ..color = star.color.withValues(alpha: alpha * 0.12)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              isHub ? 5.0 : 2.5,
            ),
        );
      }

      // Core dot
      canvas.drawCircle(
        center,
        scaledRadius,
        Paint()
          ..color = star.color.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isHub ? 1.5 : 0.6,
          ),
      );
    }
  }

  // ── Hub accent (warm halo + bright core + cross + pulse rings) ──

  void _paintHubAccent(Canvas canvas, Size size) {
    final hubCenter = _starPosAt(_hubIndex, size);
    final pulse =
        0.22 + 0.18 * ((math.sin(progress * math.pi * 2) + 1) / 2);

    // Warm halo glow around entire hub area
    canvas.drawCircle(
      hubCenter,
      40,
      Paint()
        ..color = const Color(0xFFFFA050).withValues(alpha: 0.10 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );

    // Bright white core star with mega blur
    canvas.drawCircle(
      hubCenter,
      7.0,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.70 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Hard bright center dot
    canvas.drawCircle(
      hubCenter,
      3.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0),
    );

    // Inner halo circles
    canvas.drawCircle(
      hubCenter,
      14,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      hubCenter,
      22,
      Paint()
        ..color = const Color(0xFFFFC878).withValues(alpha: 0.05 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Golden diffraction cross with visible arms
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: pulse * 0.50)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    const armLength = 30.0;
    canvas.drawLine(
      Offset(hubCenter.dx - armLength, hubCenter.dy),
      Offset(hubCenter.dx + armLength, hubCenter.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(hubCenter.dx, hubCenter.dy - armLength),
      Offset(hubCenter.dx, hubCenter.dy + armLength),
      crossPaint,
    );
    // Golden secondary cross (warm tint, slightly shorter)
    final goldenCrossPaint = Paint()
      ..color = const Color(0xFFFFA050).withValues(alpha: pulse * 0.25)
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;
    const goldenArmLength = 22.0;
    canvas.drawLine(
      Offset(hubCenter.dx - goldenArmLength, hubCenter.dy),
      Offset(hubCenter.dx + goldenArmLength, hubCenter.dy),
      goldenCrossPaint,
    );
    canvas.drawLine(
      Offset(hubCenter.dx, hubCenter.dy - goldenArmLength),
      Offset(hubCenter.dx, hubCenter.dy + goldenArmLength),
      goldenCrossPaint,
    );

    // Three expanding pulse rings at different phases
    const ringConfigs = [
      (speedFactor: 1.5, phaseOffset: 0.0, maxRadius: 45.0, baseOpacity: 0.30),
      (speedFactor: 1.0, phaseOffset: 0.5, maxRadius: 60.0, baseOpacity: 0.20),
      (speedFactor: 0.8, phaseOffset: 0.3, maxRadius: 75.0, baseOpacity: 0.14),
    ];

    for (int i = 0; i < ringConfigs.length; i++) {
      final config = ringConfigs[i];
      final ringPhase =
          (progress * config.speedFactor + config.phaseOffset) % 1.0;
      final ringRadius = 3 + ringPhase * (config.maxRadius - 3);
      final ringOpacity = config.baseOpacity * (1.0 - ringPhase);
      final strokeWidth = 0.8 * (1.0 - ringPhase * 0.7);

      if (ringOpacity > 0.01) {
        final ringColor = i == 2
            ? Color.fromRGBO(255, 145, 55, ringOpacity)
            : Colors.white.withValues(alpha: ringOpacity);
        canvas.drawCircle(
          hubCenter,
          ringRadius,
          Paint()
            ..color = ringColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

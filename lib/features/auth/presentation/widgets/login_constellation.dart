import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated constellation matching the web's LoginConstellationSVG.
///
/// Features: twinkling stars, connection edges, hub with heartbeat +
/// diffraction cross + pulse rings, traveling energy orbs along edges,
/// bridge edges that pulse, breathing nebula clouds, shooting star.
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
      duration: const Duration(seconds: 12),
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

class _Star {
  const _Star(this.x, this.y, this.r, this.phase, this.color);
  final double x, y, r, phase;
  final Color color;
}

class _Edge {
  const _Edge(this.from, this.to);
  final int from, to;
}

/// Energy orb traveling along an edge.
class _Orb {
  const _Orb(this.from, this.to, this.offset, this.color);
  final int from, to;
  final double offset; // 0-1 phase offset
  final Color color;
}

const _hub = 7;

const _stars = <_Star>[
  _Star(0.12, 0.18, 2.5, 0.00, Color(0xE6FFA05A)),
  _Star(0.25, 0.30, 1.8, 0.15, Color(0xBFFFFFFF)),
  _Star(0.10, 0.45, 3.0, 0.30, Color(0xD9FFB464)),
  _Star(0.38, 0.22, 2.0, 0.08, Color(0xB3FFFFFF)),
  _Star(0.30, 0.48, 1.5, 0.22, Color(0x8CFFFFFF)),
  _Star(0.42, 0.38, 2.0, 0.11, Color(0xB3FFFFFF)),
  _Star(0.38, 0.51, 2.5, 0.19, Color(0xCCFFFFFF)),
  _Star(0.50, 0.51, 5.5, 0.00, Color(0xFFFFFFFF)), // hub
  _Star(0.62, 0.51, 2.5, 0.19, Color(0xCCFFFFFF)),
  _Star(0.58, 0.38, 2.0, 0.11, Color(0xB3FFFFFF)),
  _Star(0.78, 0.22, 2.0, 0.08, Color(0xD996E6E1)),
  _Star(0.85, 0.43, 2.5, 0.20, Color(0xE678DCD7)),
  _Star(0.77, 0.59, 3.0, 0.28, Color(0xD964D2CD)),
  _Star(0.89, 0.17, 1.8, 0.13, Color(0xB3FFFFFF)),
  _Star(0.78, 0.71, 2.0, 0.24, Color(0x8CFFFFFF)),
  _Star(0.28, 0.10, 1.5, 0.17, Color(0x8CFFFFFF)),
  _Star(0.50, 0.08, 2.0, 0.05, Color(0xA6FFFFFF)),
  _Star(0.72, 0.10, 1.5, 0.25, Color(0xB396E6E1)),
  _Star(0.14, 0.12, 2.0, 0.03, Color(0xB3FFB464)),
  _Star(0.86, 0.12, 1.5, 0.20, Color(0xB396E6E1)),
];

const _normalEdges = <_Edge>[
  _Edge(0, 1), _Edge(1, 2), _Edge(2, 4), _Edge(0, 3),
  _Edge(3, 5), _Edge(4, 5), _Edge(5, 6),
  _Edge(8, 9), _Edge(9, 11), _Edge(10, 11),
  _Edge(11, 12), _Edge(12, 14), _Edge(10, 13),
  _Edge(18, 15), _Edge(15, 16), _Edge(16, 17), _Edge(17, 19),
  _Edge(3, 15), _Edge(16, 9), _Edge(17, 13),
];

const _bridgeEdges = <_Edge>[_Edge(6, 7), _Edge(7, 8)];

const _orbs = <_Orb>[
  _Orb(0, 1, 0.00, Color(0xCCFFD898)),   // orange
  _Orb(3, 5, 0.11, Color(0xCCFFD898)),   // orange
  _Orb(6, 7, 0.00, Color(0xCCFFFFFF)),   // white (bridge)
  _Orb(7, 8, 0.06, Color(0xCCFFFFFF)),   // white (bridge)
  _Orb(10, 11, 0.04, Color(0xCCA0FFF8)), // teal
  _Orb(11, 12, 0.16, Color(0xCCA0FFF8)), // teal
  _Orb(15, 16, 0.07, Color(0xCCFFFFFF)), // white
  _Orb(16, 9, 0.18, Color(0xCCFFD898)),  // orange
];

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _drawNebulae(canvas, size);
    _drawEdges(canvas, size);
    _drawBridgeEdges(canvas, size);
    _drawOrbs(canvas, size);
    _drawStars(canvas, size);
    _drawHubCross(canvas, size);
    _drawHubBloom(canvas, size);
    _drawHubRings(canvas, size);
    _drawShootingStar(canvas, size);
  }

  Offset _pos(_Star s, Size sz) => Offset(s.x * sz.width, s.y * sz.height);

  // ── Nebula clouds (breathing) ──────────────────────────────────
  void _drawNebulae(Canvas canvas, Size size) {
    final breathe = 0.5 + 0.5 * math.sin(progress * math.pi * 2 * 0.4);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.32),
        width: size.width * 0.50,
        height: size.height * 0.30,
      ),
      Paint()
        ..color = const Color(0xFFFF8C3C).withValues(alpha: 0.10 * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.76, size.height * 0.55),
        width: size.width * 0.45,
        height: size.height * 0.28,
      ),
      Paint()
        ..color = const Color(0xFF00C8C0).withValues(alpha: 0.08 * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
  }

  // ── Normal edges (dim hairlines) ───────────────────────────────
  void _drawEdges(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (final e in _normalEdges) {
      canvas.drawLine(_pos(_stars[e.from], size), _pos(_stars[e.to], size), paint);
    }
  }

  // ── Bridge edges (pulse glow) ──────────────────────────────────
  void _drawBridgeEdges(Canvas canvas, Size size) {
    final pulse = 0.28 + 0.44 * ((math.sin(progress * math.pi * 2 * 0.8) + 1) / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: pulse)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (final e in _bridgeEdges) {
      canvas.drawLine(_pos(_stars[e.from], size), _pos(_stars[e.to], size), paint);
    }
  }

  // ── Traveling energy orbs ──────────────────────────────────────
  void _drawOrbs(Canvas canvas, Size size) {
    for (final orb in _orbs) {
      final from = _pos(_stars[orb.from], size);
      final to = _pos(_stars[orb.to], size);

      // Each orb travels its edge over ~4 seconds, offset by orb.offset
      final t = ((progress * 3.0 + orb.offset) % 1.0);

      // Fade in at start, fade out at end
      final opacity = t < 0.08
          ? t / 0.08
          : t > 0.92
              ? (1.0 - t) / 0.08
              : 1.0;

      if (opacity < 0.01) continue;

      final orbPos = Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t,
      );

      // Outer glow
      canvas.drawCircle(
        orbPos,
        7,
        Paint()
          ..color = orb.color.withValues(alpha: 0.3 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Core
      canvas.drawCircle(
        orbPos,
        3,
        Paint()
          ..color = orb.color.withValues(alpha: 0.8 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ── Star nodes (twinkle) ───────────────────────────────────────
  void _drawStars(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final isHub = i == _hub;
      final center = _pos(s, size);

      // Hub heartbeat: scale 1→1.72→1→1.38→1 over the cycle
      double twinkle;
      double scale;
      if (isHub) {
        final hbPhase = (progress * 3.0) % 1.0;
        if (hbPhase < 0.14) {
          scale = 1.0 + 0.72 * (hbPhase / 0.14);
          twinkle = 0.65 + 0.35 * (hbPhase / 0.14);
        } else if (hbPhase < 0.28) {
          scale = 1.72 - 0.72 * ((hbPhase - 0.14) / 0.14);
          twinkle = 1.0 - 0.35 * ((hbPhase - 0.14) / 0.14);
        } else if (hbPhase < 0.44) {
          scale = 1.0 + 0.38 * ((hbPhase - 0.28) / 0.16);
          twinkle = 0.65 + 0.25 * ((hbPhase - 0.28) / 0.16);
        } else if (hbPhase < 0.60) {
          scale = 1.38 - 0.38 * ((hbPhase - 0.44) / 0.16);
          twinkle = 0.90 - 0.25 * ((hbPhase - 0.44) / 0.16);
        } else {
          scale = 1.0;
          twinkle = 0.65;
        }
      } else {
        final phase = ((progress + s.phase) % 1.0);
        twinkle = 0.30 + 0.70 * ((math.sin(phase * math.pi * 2) + 1) / 2);
        scale = 0.92 + 0.15 * twinkle;
      }

      final radius = s.r * scale;
      final alpha = s.color.a * twinkle;

      // Glow layer
      canvas.drawCircle(
        center,
        radius * 1.8,
        Paint()
          ..color = s.color.withValues(alpha: alpha * 0.25)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isHub ? 12.0 : s.r >= 2.5 ? 5.0 : 2.5,
          ),
      );

      // Main star
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = s.color.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            isHub ? 4.0 : 1.5,
          ),
      );

      // Sharp core
      canvas.drawCircle(
        center,
        radius * 0.4,
        Paint()..color = s.color.withValues(alpha: alpha),
      );
    }
  }

  // ── Hub diffraction cross ──────────────────────────────────────
  void _drawHubCross(Canvas canvas, Size size) {
    final hubCenter = _pos(_stars[_hub], size);
    final pulse = 0.38 + 0.44 * ((math.sin(progress * math.pi * 2 * 1.0) + 1) / 2);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: pulse * 0.7)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    const armLen = 32.0;
    canvas.drawLine(
      Offset(hubCenter.dx - armLen, hubCenter.dy),
      Offset(hubCenter.dx + armLen, hubCenter.dy),
      paint,
    );
    canvas.drawLine(
      Offset(hubCenter.dx, hubCenter.dy - armLen),
      Offset(hubCenter.dx, hubCenter.dy + armLen),
      paint,
    );
  }

  // ── Hub bloom (mega glow) ──────────────────────────────────────
  void _drawHubBloom(Canvas canvas, Size size) {
    final hubCenter = _pos(_stars[_hub], size);

    canvas.drawCircle(
      hubCenter,
      24,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );
    canvas.drawCircle(
      hubCenter,
      32,
      Paint()
        ..color = const Color(0xFFFF9138).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );

    // Inner halos
    canvas.drawCircle(
      hubCenter,
      16,
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawCircle(
      hubCenter,
      10,
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );
  }

  // ── Hub pulse rings ────────────────────────────────────────────
  void _drawHubRings(Canvas canvas, Size size) {
    final hubCenter = _pos(_stars[_hub], size);

    const ringConfigs = <(double, double, Color)>[
      (0.0, 62, Color(0x9EFFFFFF)),
      (0.33, 56, Color(0x6BFFFFFF)),
      (0.21, 84, Color(0xB8FF9137)),
    ];

    for (final (phaseOffset, maxR, color) in ringConfigs) {
      final phase = ((progress * 2.5 + phaseOffset) % 1.0);
      final radius = 6 + phase * (maxR - 6);
      final opacity = 0.68 * (1 - phase);
      final strokeW = 1.5 * (1 - phase * 0.9);

      if (opacity > 0.01) {
        canvas.drawCircle(
          hubCenter,
          radius,
          Paint()
            ..color = color.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW,
        );
      }
    }
  }

  // ── Shooting star ──────────────────────────────────────────────
  void _drawShootingStar(Canvas canvas, Size size) {
    // Shoots across every ~18 seconds, visible for ~26% of cycle
    final shotPhase = (progress * 0.67) % 1.0; // slowed
    if (shotPhase > 0.26) return;

    final t = shotPhase / 0.26;
    final opacity = t < 0.04 / 0.26
        ? t / (0.04 / 0.26) * 0.92
        : t < 0.85
            ? 0.92
            : 0.92 * (1.0 - (t - 0.85) / 0.15);

    if (opacity < 0.01) return;

    final startX = -40.0 + t * (size.width + 80);
    final startY = size.height * 0.3 - t * size.height * 0.15;
    final tailLen = 60.0;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(Rect.fromLTWH(startX - tailLen, startY, tailLen, 2))
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(startX - tailLen, startY + tailLen * 0.25),
      Offset(startX, startY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

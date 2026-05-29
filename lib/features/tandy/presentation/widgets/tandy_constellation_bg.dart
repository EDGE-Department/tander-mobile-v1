import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ultra-minimalistic ambient constellation background for the Tandy chat.
/// 5 nodes, 3 ultra-faint edges, gentle drift animation only.
/// Barely-perceptible — never competes with content.
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
        builder: (context, _) => CustomPaint(
          painter: _ConstellationPainter(_controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────

class _Star {
  const _Star(this.x, this.y, this.r, this.phase, this.color);
  final double x, y, r, phase;
  final Color color;
}

class _Edge {
  const _Edge(this.from, this.to);
  final int from, to;
}

// Normalized coordinates (0–1), scaled to canvas at paint time.
// 5 nodes: removed overlapping center-left node for cleaner spread.
const List<_Star> _stars = [
  _Star(0.15, 0.20, 1.4, 0.00, Color(0x21DC761E)), // orange — top-left
  _Star(0.50, 0.50, 2.0, 0.25, Color(0x1ADC761E)), // orange — center anchor
  _Star(0.70, 0.26, 1.4, 0.75, Color(0x1F0F9D94)), // teal — right
  _Star(0.85, 0.44, 1.6, 0.10, Color(0x1A0F9D94)), // teal — far right
  _Star(0.27, 0.57, 1.2, 0.62, Color(0x14B47828)), // neutral warm — bottom-left
];

// 3 edges: one connected path (0→1→4) plus one pair (2→3)
const List<_Edge> _edges = [_Edge(0, 1), _Edge(1, 4), _Edge(2, 3)];

// ── Painter ───────────────────────────────────────────────────────────────

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter(this.time);
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _drawEdges(canvas, size);
    _drawStars(canvas, size);
  }

  Offset _pos(int index, Size size) =>
      Offset(_stars[index].x * size.width, _stars[index].y * size.height);

  void _drawEdges(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0FA0641E)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final edge in _edges) {
      canvas.drawLine(_pos(edge.from, size), _pos(edge.to, size), paint);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    const twoPi = math.pi * 2;

    for (int i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final pos = _pos(i, size);

      // Slow drift: each node has its own phase offset
      // Cycle spread across 14–20s via phase offset in the 20s controller
      final t = (time + star.phase) % 1.0;
      final opacity = 0.05 + 0.08 * ((math.sin(t * twoPi) + 1) / 2);

      canvas.drawCircle(
        pos,
        star.r,
        Paint()..color = star.color.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => time != old.time;
}

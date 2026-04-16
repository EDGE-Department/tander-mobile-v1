import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/splash/presentation/widgets/splash_painters.dart';

// ── Gradients ────────────────────────────────────────────────────────

/// Web: --gradient-auth-bg: linear-gradient(135deg, #F07040…#20BF68)
const LinearGradient authGradient = LinearGradient(
  begin: Alignment(-1, -1),
  end: Alignment(1, 1),
  colors: [
    Color(0xFFF07040),
    Color(0xFFE86035),
    Color(0xFF2EC878),
    Color(0xFF20BF68),
  ],
  stops: [0.0, 0.30, 0.70, 1.0],
);

const LinearGradient parchmentGradient = LinearGradient(
  begin: Alignment(-0.15, -1.0),
  end: Alignment(0.15, 1.0),
  colors: [
    Color(0xFFFEF7EE),
    Color(0xFFFEFAF4),
    Color(0xFFFFF8EF),
    Color(0xFFFDF4E8),
  ],
  stops: [0.0, 0.35, 0.65, 1.0],
);

// ── Constellation painter ────────────────────────────────────────────

class ConstellationNode {
  const ConstellationNode(this.x, this.y, this.radius, this.color);

  final double x;
  final double y;
  final double radius;
  final Color color;
}

class AuthConstellationPainter extends CustomPainter {
  const AuthConstellationPainter();

  static const List<ConstellationNode> _nodes = [
    ConstellationNode(0.12, 0.34, 2.2, Color(0xE6FFA05A)),
    ConstellationNode(0.25, 0.24, 1.7, Color(0xBFFFFFFF)),
    ConstellationNode(0.23, 0.58, 1.6, Color(0x8CFFFFFF)),
    ConstellationNode(0.39, 0.46, 2.1, Color(0xCCFFFFFF)),
    ConstellationNode(0.50, 0.50, 4.4, Color(0xFFFFFFFF)),
    ConstellationNode(0.61, 0.45, 2.1, Color(0xCCFFFFFF)),
    ConstellationNode(0.76, 0.24, 1.7, Color(0xD996E6DF)),
    ConstellationNode(0.85, 0.42, 2.3, Color(0xE678DCD7)),
    ConstellationNode(0.78, 0.62, 1.8, Color(0x8CFFFFFF)),
    ConstellationNode(0.50, 0.16, 1.7, Color(0xA6FFFFFF)),
    ConstellationNode(0.05, 0.20, 1.4, Color(0xB3FFB464)),
    ConstellationNode(0.95, 0.18, 1.4, Color(0xB396E6DF)),
  ];

  static const List<List<int>> _normalEdges = [
    [0, 1], [0, 3], [2, 3], [5, 6], [5, 7], [7, 8], [9, 4], [10, 0], [11, 6],
  ];

  static const List<List<int>> _bridgeEdges = [
    [3, 4], [4, 5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    final bridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..strokeWidth = 1.05
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    for (final edge in _normalEdges) {
      canvas.drawLine(
        _resolve(size, _nodes[edge[0]]),
        _resolve(size, _nodes[edge[1]]),
        linePaint,
      );
    }
    for (final edge in _bridgeEdges) {
      canvas.drawLine(
        _resolve(size, _nodes[edge[0]]),
        _resolve(size, _nodes[edge[1]]),
        bridgePaint,
      );
    }

    final hubGlowPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(_resolve(size, _nodes[4]), 18, hubGlowPaint);

    for (final node in _nodes) {
      final offset = _resolve(size, node);
      canvas.drawCircle(
        offset,
        node.radius * 2.2,
        Paint()
          ..color = node.color.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            node.radius >= 4 ? 8 : 3,
          ),
      );
      canvas.drawCircle(offset, node.radius, Paint()..color = node.color);
    }
  }

  static Offset _resolve(Size size, ConstellationNode node) {
    const hScale = 1.08;
    const vScale = 0.90;
    const hInset = 0.08;
    const vInset = 0.10;
    return Offset(
      size.width *
          clampDouble(0.5 + (node.x - 0.5) * hScale, hInset, 1 - hInset),
      size.height *
          clampDouble(0.5 + (node.y - 0.5) * vScale, vInset, 1 - vInset),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Grain painter ────────────────────────────────────────────────────

class AuthGrainPainter extends CustomPainter {
  const AuthGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int i = 0; i < 520; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.2 + random.nextDouble() * 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Parchment dot grid painter ───────────────────────────────────────

class ParchmentDotGridPainter extends CustomPainter {
  const ParchmentDotGridPainter({this.spacing = 26});

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14B46414)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParchmentDotGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing;
  }
}

// ── Wave seam painter ────────────────────────────────────────────────

class WaveSeamPainter extends CustomPainter {
  const WaveSeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.53, 0)
      ..cubicTo(size.width * 0.66, size.height * 0.078, size.width * 0.80,
          size.height * 0.143, size.width * 0.59, size.height * 0.266)
      ..cubicTo(size.width * 0.44, size.height * 0.39, size.width * 0.72,
          size.height * 0.456, size.width * 0.56, size.height * 0.576)
      ..cubicTo(size.width * 0.44, size.height * 0.696, size.width * 0.67,
          size.height * 0.75, size.width * 0.53, size.height * 0.876)
      ..cubicTo(size.width * 0.44, size.height * 0.96, size.width * 0.56,
          size.height * 0.983, size.width * 0.53, size.height);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x38E6A03C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Header scene (constellation + grain + 60+ watermark) ─────────────

class AuthHeaderScene extends StatefulWidget {
  const AuthHeaderScene({super.key});

  @override
  State<AuthHeaderScene> createState() => _AuthHeaderSceneState();
}

class _AuthHeaderSceneState extends State<AuthHeaderScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: AuthGrainPainter()),
            ),
          ),
          // Web's 19-node animated constellation at 45% opacity
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => CustomPaint(
                    painter: SplashConstellationPainter(_ctrl.value),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fontSize =
                      clampDouble(constraints.maxWidth * 0.34, 116, 176);
                  return Center(
                    child: Transform.translate(
                      offset: Offset(0, fontSize * 0.08),
                      child: Text(
                        '60+',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: fontSize,
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          letterSpacing: -0.05 * fontSize,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frosted parchment sheet ──────────────────────────────────────────

class AuthParchmentSheet extends StatelessWidget {
  const AuthParchmentSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const AuthSheetHandle(),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Sheet drag handle ────────────────────────────────────────────────

class AuthSheetHandle extends StatelessWidget {
  const AuthSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

// ── Parchment form panel (right side for tablet/landscape) ───────────

class AuthParchmentFormPanel extends StatelessWidget {
  const AuthParchmentFormPanel({
    required this.child,
    this.maxWidth = 400,
    this.padding = const EdgeInsets.all(32),
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: parchmentGradient),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child:
                    CustomPaint(painter: ParchmentDotGridPainter(spacing: 24)),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                width: 420,
                height: 420,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(0x1AE67E22),
                      Color(0x0AE67E22),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 0.85],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            left: false,
            child: Center(
              child: SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

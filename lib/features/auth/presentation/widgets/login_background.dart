import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_constellation.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Web: --gradient-auth-bg: linear-gradient(135deg, #F07040 0%, #E86035 30%, #2EC878 70%, #20BF68 100%)
const _authGradientColors = [
  Color(0xFFF07040),
  Color(0xFFE86035),
  Color(0xFF2EC878),
  Color(0xFF20BF68),
];
const _authGradientStops = [0.0, 0.30, 0.70, 1.0];

const double _headerHeightFraction = 0.20;

/// How far the form panel overlaps the header (web `-mt-6` = 24px).
const double headerOverlap = 24;

// ── Header gradient background ──────────────────────────────────────

class LoginHeaderBackground extends StatefulWidget {
  const LoginHeaderBackground({
    required this.headerHeight,
    this.showSocialOrbs = true,
    super.key,
  });

  final double headerHeight;
  final bool showSocialOrbs;

  @override
  State<LoginHeaderBackground> createState() => _LoginHeaderBackgroundState();
}

class _LoginHeaderBackgroundState extends State<LoginHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = widget.headerHeight;

    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Auth gradient (135deg, orange->green)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1, -1),
                  end: Alignment(1, 1),
                  colors: _authGradientColors,
                  stops: _authGradientStops,
                ),
              ),
            ),
          ),

          const LoginConstellation(),

          // Vivid aurora: warm orange blob top-left (with drift)
          AnimatedBuilder(
            animation: _driftController,
            builder: (_, child) {
              final phase = _driftController.value * math.pi * 2;
              final driftX = math.sin(phase) * 6;
              final driftY = math.cos(phase * 0.7) * 4;
              return Positioned(
                top: -headerHeight * 0.08 + driftY,
                left: -headerHeight * 0.05 + driftX,
                child: child!,
              );
            },
            child: Container(
              width: headerHeight * 0.65,
              height: headerHeight * 0.55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headerHeight * 0.45),
                  topRight: Radius.circular(headerHeight * 0.55),
                  bottomLeft: Radius.circular(headerHeight * 0.50),
                  bottomRight: Radius.circular(headerHeight * 0.50),
                ),
                gradient: const RadialGradient(
                  colors: [
                    Color(
                      0x8CFF8C46,
                    ), // rgba(255,140,70,0.55) — increased from 0.44
                    Color(
                      0x4DF06432,
                    ), // rgba(240,100,50,0.30) — increased from 0.22
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.50, 0.75],
                ),
              ),
            ),
          ),

          // Vivid aurora: teal blob bottom-right (with drift, 18s effective period)
          AnimatedBuilder(
            animation: _driftController,
            builder: (_, child) {
              const tealPhaseRatio = 14.0 / 18.0;
              final phase = _driftController.value * math.pi * 2;
              final driftX =
                  math.sin(phase * 0.8 * tealPhaseRatio + math.pi) * 5;
              final driftY =
                  math.cos(phase * 0.6 * tealPhaseRatio + math.pi) * 3;
              return Positioned(
                bottom: -headerHeight * 0.05 + driftY,
                right: -headerHeight * 0.08 + driftX,
                child: child!,
              );
            },
            child: Container(
              width: headerHeight * 0.40,
              height: headerHeight * 0.35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headerHeight * 0.50),
                  topRight: Radius.circular(headerHeight * 0.40),
                  bottomLeft: Radius.circular(headerHeight * 0.60),
                  bottomRight: Radius.circular(headerHeight * 0.40),
                ),
                gradient: const RadialGradient(
                  colors: [
                    Color(
                      0x382EC88C,
                    ), // rgba(46,200,140,0.22) — reduced from 0.28
                    Color(
                      0x1C0FA094,
                    ), // rgba(15,160,148,0.11) — reduced from 0.14
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 0.70],
                ),
              ),
            ),
          ),

          // Bottom vignette
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: headerHeight * 0.4,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0x6B120400), // rgba(18,4,0,0.42)
                    Color(0x1F0A0200), // rgba(10,2,0,0.12)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Film grain texture — SVG noise equivalent at opacity 0.05
          const Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _GrainPainter()),
            ),
          ),

          // Corner highlight
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.76, -0.84),
                  radius: 0.4,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Floating social icons are configurable because forgot-password
          // still uses them, while login no longer does.
          if (widget.showSocialOrbs) const _SocialOrbs(),

          // "60+" watermark
          const _SixtyPlusWatermark(),
        ],
      ),
    );
  }
}

double resolveHeaderHeight(double screenHeight) {
  return screenHeight * _headerHeightFraction;
}

// ── Social orbs (Heart, ChatCircle, Star) ───────────────────────────

class _SocialOrbs extends StatefulWidget {
  const _SocialOrbs();

  @override
  State<_SocialOrbs> createState() => _SocialOrbsState();
}

class _SocialOrbsState extends State<_SocialOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _driftController,
        builder: (_, _) {
          final phase = _driftController.value * 2 * math.pi;
          return Stack(
            children: [
              // Connecting lines between orbs
              const Positioned.fill(
                child: CustomPaint(painter: _OrbConnectionsPainter()),
              ),
              // Heart — left area, pink/orange glow
              _FloatingOrb(
                left: 0.12,
                top: 0.14,
                icon: Icons.favorite,
                size: 32,
                color: const Color(0xFFFFB088),
                glowColor: const Color(0xA0FFB088),
                glowRadius: 20,
                driftX: math.sin(phase) * 8,
                driftY: math.cos(phase * 0.7) * 6,
              ),
              // ChatCircle — top-center, warm teal tint
              _FloatingOrb(
                left: 0.44,
                top: 0.07,
                icon: Icons.chat_bubble_outline_rounded,
                size: 28,
                color: const Color(0xFF5BBFB3),
                glowColor: const Color(0x805BBFB3),
                glowRadius: 18,
                driftX: math.sin(phase + math.pi / 3) * 10,
                driftY: math.cos(phase * 0.8 + math.pi / 3) * 7,
              ),
              // Star — top-right, golden glow
              _FloatingOrb(
                left: 0.74,
                top: 0.13,
                icon: Icons.star,
                size: 26,
                color: const Color(0xFFFFE17A),
                glowColor: const Color(0x8CFFE17A),
                glowRadius: 18,
                driftX: math.sin(phase + 2 * math.pi / 3) * 7,
                driftY: math.cos(phase * 0.6 + 2 * math.pi / 3) * 9,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({
    required this.left,
    required this.top,
    required this.icon,
    required this.size,
    required this.color,
    required this.glowColor,
    this.glowRadius = 10,
    this.driftX = 0,
    this.driftY = 0,
  });

  final double left;
  final double top;
  final IconData icon;
  final double size;
  final Color color;
  final Color glowColor;
  final double glowRadius;
  final double driftX;
  final double driftY;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return Positioned(
      left: screenSize.width * left - size / 2 + driftX,
      top: screenSize.height * 0.38 * top + driftY,
      child: Icon(
        icon,
        size: size,
        color: color,
        shadows: [
          Shadow(color: glowColor, blurRadius: glowRadius),
          Shadow(
            color: glowColor.withValues(alpha: glowColor.a * 0.5),
            blurRadius: glowRadius * 2,
          ),
          Shadow(
            color: glowColor.withValues(alpha: glowColor.a * 0.25),
            blurRadius: glowRadius * 3,
          ),
        ],
      ),
    );
  }
}

// ── Orb connections painter ──────────────────────────────────────────

/// Draws thin white lines connecting the three social orb positions,
/// matching the web's SVG connecting lines.
class _OrbConnectionsPainter extends CustomPainter {
  const _OrbConnectionsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0x26FFFFFF) // ~15% opacity white
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Orb fractional positions: Heart (0.12, 0.14), Chat (0.44, 0.07), Star (0.74, 0.13)
    // Y is relative to 38% of screen height (header fraction)
    final heart = Offset(size.width * 0.12, size.height * 0.14);
    final chat = Offset(size.width * 0.44, size.height * 0.07);
    final star = Offset(size.width * 0.74, size.height * 0.13);

    canvas.drawLine(heart, chat, paint);
    canvas.drawLine(chat, star, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── "60+" watermark ─────────────────────────────────────────────────

class _SixtyPlusWatermark extends StatelessWidget {
  const _SixtyPlusWatermark();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = (screenWidth * 0.55).clamp(140.0, 240.0);

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: Offset(0, fontSize * 0.10),
          child: Text(
            '60+',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              color: Colors.white.withValues(alpha: 0.035), // web mobile: 0.035
              height: 1,
              letterSpacing: -0.04 * fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Online count badge ──────────────────────────────────────────────

class OnlineCountBadge extends StatefulWidget {
  const OnlineCountBadge({
    required this.count,
    this.isLightBackground = false,
    this.useSeniorsLabel = false,
    super.key,
  });

  final int count;
  final bool isLightBackground;
  final bool useSeniorsLabel;

  @override
  State<OnlineCountBadge> createState() => _OnlineCountBadgeState();
}

class _OnlineCountBadgeState extends State<OnlineCountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pingController;
  late final Animation<double> _pingScale;
  late final Animation<double> _pingOpacity;

  @override
  void initState() {
    super.initState();
    _pingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pingScale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _pingController, curve: AppCurves.premiumEase),
    );
    _pingOpacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pingController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLightBackground;
    final label = widget.useSeniorsLabel
        ? '${widget.count} seniors online now'
        : '${widget.count} online now';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLight
            ? AppColors.primaryLight
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isLight
              ? const Color(0x38E67E22)
              : Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pingController,
                  builder: (_, _) => Transform.scale(
                    scale: _pingScale.value,
                    child: Opacity(
                      opacity: _pingOpacity.value,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6EE7B7),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isLight ? AppColors.primaryAccessible : Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Simulated online count ──────────────────────────────────────────

const int _minCount = 127;
const int _maxCount = 284;

class SimulatedOnlineCount extends ValueNotifier<int> {
  SimulatedOnlineCount()
    : super(_minCount + math.Random().nextInt(_maxCount - _minCount)) {
    _tick();
  }

  void _tick() {
    Future<void>.delayed(
      Duration(milliseconds: 3000 + math.Random().nextInt(4000)),
      () {
        if (!hasListeners) return;
        final delta = math.Random().nextInt(7) - 3;
        value = (value + delta).clamp(_minCount, _maxCount);
        _tick();
      },
    );
  }
}

// ── Film grain painter ──────────────────────────────────────────────

/// Draws random small white dots to simulate film grain / SVG noise.
/// Uses a fixed seed for consistent rendering across rebuilds.
class _GrainPainter extends CustomPainter {
  const _GrainPainter();

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

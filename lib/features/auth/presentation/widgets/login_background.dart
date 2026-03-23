import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_constellation.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Web: --gradient-auth-bg: linear-gradient(135deg, #F07040 0%, #E86035 30%, #2EC878 70%, #20BF68 100%)
const _authGradientColors = [
  Color(0xFFF07040),
  Color(0xFFE86035),
  Color(0xFF2EC878),
  Color(0xFF20BF68),
];
const _authGradientStops = [0.0, 0.30, 0.70, 1.0];

const double _headerMinHeight = 268;
const double _headerMaxHeight = 316;
const double _headerHeightFraction = 0.38;

/// How far the form panel overlaps the header (web `-mt-6` = 24px).
const double headerOverlap = 24;

// ── Header gradient background ──────────────────────────────────────

class LoginHeaderBackground extends StatelessWidget {
  const LoginHeaderBackground({required this.headerHeight, super.key});

  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Auth gradient (135deg, orange→green)
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

          // Vivid aurora: warm orange blob top-left
          Positioned(
            top: -headerHeight * 0.08,
            left: -headerHeight * 0.05,
            child: Container(
              width: headerHeight * 0.5,
              height: headerHeight * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headerHeight * 0.45),
                  topRight: Radius.circular(headerHeight * 0.55),
                  bottomLeft: Radius.circular(headerHeight * 0.50),
                  bottomRight: Radius.circular(headerHeight * 0.50),
                ),
                gradient: const RadialGradient(
                  colors: [
                    Color(0x70FF8C46), // rgba(255,140,70,0.44)
                    Color(0x38F06432), // rgba(240,100,50,0.22)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 0.70],
                ),
              ),
            ),
          ),

          // Vivid aurora: teal blob bottom-right
          Positioned(
            bottom: -headerHeight * 0.05,
            right: -headerHeight * 0.08,
            child: Container(
              width: headerHeight * 0.45,
              height: headerHeight * 0.40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(headerHeight * 0.50),
                  topRight: Radius.circular(headerHeight * 0.40),
                  bottomLeft: Radius.circular(headerHeight * 0.60),
                  bottomRight: Radius.circular(headerHeight * 0.40),
                ),
                gradient: const RadialGradient(
                  colors: [
                    Color(0x472EC88C), // rgba(46,200,140,0.28)
                    Color(0x240FA094), // rgba(15,160,148,0.14)
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
                    Color(0x59781E05), // rgba(120,30,5,0.35)
                    Color(0x1F501405), // rgba(80,20,5,0.12)
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.25, 0.50],
                ),
              ),
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

          // Constellation (twinkling stars + edges + hub pulse)
          const LoginConstellation(),

          // Social orbs (Heart, ChatCircle, Star)
          const _SocialOrbs(),

          // "60+" watermark
          const _SixtyPlusWatermark(),
        ],
      ),
    );
  }
}

double resolveHeaderHeight(double screenHeight) {
  return (screenHeight * _headerHeightFraction)
      .clamp(_headerMinHeight, _headerMaxHeight);
}

// ── Social orbs (Heart, ChatCircle, Star) ───────────────────────────

class _SocialOrbs extends StatelessWidget {
  const _SocialOrbs();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          // Heart — top-left, warm peach glow
          _FloatingOrb(
            left: 0.12,
            top: 0.14,
            icon: Icons.favorite,
            size: 28,
            color: Color(0xFFFFB088),
            glowColor: Color(0x73FFB088),
          ),
          // ChatCircle — top-center, white glow
          _FloatingOrb(
            left: 0.44,
            top: 0.07,
            icon: Icons.chat_bubble,
            size: 24,
            color: Color(0xE6FFFFFF),
            glowColor: Color(0x59FFFFFF),
          ),
          // Star — top-right, gold glow
          _FloatingOrb(
            left: 0.74,
            top: 0.13,
            icon: Icons.star,
            size: 22,
            color: Color(0xFFFFE17A),
            glowColor: Color(0x66FFE17A),
          ),
        ],
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
  });

  final double left;
  final double top;
  final IconData icon;
  final double size;
  final Color color;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.sizeOf(context).width * left - size / 2,
      top: MediaQuery.sizeOf(context).height * 0.38 * top,
      child: Icon(
        icon,
        size: size,
        color: color,
        shadows: [
          Shadow(color: glowColor, blurRadius: 10),
        ],
      ),
    );
  }
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
              color: Colors.white.withValues(alpha: 0.035),
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
    super.key,
  });

  final int count;
  final bool isLightBackground;

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
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pingScale = Tween<double>(begin: 0.6, end: 2.0).animate(
      CurvedAnimation(parent: _pingController, curve: AppCurves.premiumEase),
    );
    _pingOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pingController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isLightBackground;

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
            isLight
                ? '${widget.count} online now'
                : '${widget.count} seniors online now',
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

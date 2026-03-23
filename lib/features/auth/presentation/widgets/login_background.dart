import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Header gradient start: dark warm tone matching web's `--gradient-auth-bg`.
const Color _gradientStart = AppColors.darkWarm;

/// Header gradient end: secondary teal.
const Color _gradientEnd = AppColors.secondary;

/// Minimum height of the header region (matches web `minHeight: 268`).
const double _headerMinHeight = 268;

/// Maximum height of the header region (matches web `maxHeight: 316`).
const double _headerMaxHeight = 316;

/// Header's fraction of screen height, clamped between min/max.
const double _headerHeightFraction = 0.38;

/// How far the form panel overlaps the header (web `-mt-6` = 24px).
const double headerOverlap = 24;

// ── Header gradient background ──────────────────────────────────────

/// Full-width gradient header for the mobile login screen.
///
/// Matches the web's mobile header section: dark-warm to teal gradient
/// with decorative translucent orbs and a faint "60+" watermark.
class LoginHeaderBackground extends StatelessWidget {
  const LoginHeaderBackground({required this.headerHeight, super.key});

  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight,
      width: double.infinity,
      child: const Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Gradient fill
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_gradientStart, _gradientEnd],
                ),
              ),
            ),
          ),

          // Decorative orbs
          _HeaderOrbs(),

          // "60+" watermark
          _SixtyPlusWatermark(),
        ],
      ),
    );
  }
}

/// Calculates the header height from screen size, clamped to web's range.
double resolveHeaderHeight(double screenHeight) {
  return (screenHeight * _headerHeightFraction)
      .clamp(_headerMinHeight, _headerMaxHeight);
}

// ── Decorative orbs ─────────────────────────────────────────────────

/// Translucent floating orbs that add depth to the gradient header,
/// matching the web's `<SocialOrbs />` component.
class _HeaderOrbs extends StatelessWidget {
  const _HeaderOrbs();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return IgnorePointer(
      child: Stack(
        children: [
          _Orb(
            diameter: screenWidth * 0.5,
            color: AppColors.primary.withValues(alpha: 0.10),
            top: -screenWidth * 0.1,
            left: -screenWidth * 0.12,
          ),
          _Orb(
            diameter: screenWidth * 0.35,
            color: AppColors.secondary.withValues(alpha: 0.08),
            top: 40,
            right: -screenWidth * 0.08,
          ),
        ],
      ),
    );
  }
}

/// Single translucent circular gradient orb, absolutely positioned.
class _Orb extends StatelessWidget {
  const _Orb({
    required this.diameter,
    required this.color,
    this.top,
    this.left,
    this.right,
  });

  final double diameter;
  final Color color;
  final double? top;
  final double? left;
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

// ── "60+" watermark ─────────────────────────────────────────────────

/// Faint "60+" text centered in the header, matching the web's
/// `clamp(140px, 55vw, 240px)` at 3.5% opacity.
class _SixtyPlusWatermark extends StatelessWidget {
  const _SixtyPlusWatermark();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fontSize = (screenWidth * 0.55).clamp(140.0, 240.0);

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 10),
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

// ── Online count ping dot ───────────────────────────────────────────

/// Animated emerald ping dot + online count text.
///
/// Matches the web's pulse animation on the green indicator dot.
class OnlineCountBadge extends StatefulWidget {
  const OnlineCountBadge({
    required this.count,
    this.isLightBackground = false,
    super.key,
  });

  final int count;

  /// When `true`, uses primary-tinted styling for the form panel.
  /// When `false`, uses white/transparent styling for the header.
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
              ? const Color(0x38E67E22) // rgba(230,126,34,0.22)
              : Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ping dot
          SizedBox(
            width: 8,
            height: 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated ping ring
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
                          color: Color(0xFF6EE7B7), // emerald-300
                        ),
                      ),
                    ),
                  ),
                ),
                // Static dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399), // emerald-400
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

/// Generates a slowly-drifting simulated online count between
/// [_minCount] and [_maxCount], matching the web's hook.
const int _minCount = 127;
const int _maxCount = 284;

/// Produces a stream-like ticker that fluctuates an integer to simulate
/// a live online count. Returns the count as a [ValueNotifier] so
/// multiple widgets can share the same value without extra rebuilds.
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
        final delta = math.Random().nextInt(7) - 3; // -3..+3
        value = (value + delta).clamp(_minCount, _maxCount);
        _tick();
      },
    );
  }
}

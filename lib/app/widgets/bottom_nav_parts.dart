import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';

// ── Tab descriptor ──────────────────────────────────────────────────────────

/// Immutable descriptor for a single bottom-nav tab.
@immutable
class NavTabDescriptor {
  const NavTabDescriptor({
    required this.id,
    required this.label,
    required this.route,
    required this.iconAsset,
    this.isTandy = false,
  });

  /// Unique identifier used for badge resolution.
  final String id;

  /// Human-readable label displayed beneath the icon.
  final String label;

  /// GoRouter path for this tab.
  final String route;

  /// Asset path to the 24x24 icon image.
  final String iconAsset;

  /// Whether this tab represents the Tandy AI companion.
  final bool isTandy;
}

// ── Design constants ────────────────────────────────────────────────────────

/// Pixel-spec constants extracted from the web app for the bottom nav bar.
///
/// Centralised here to keep both `bottom_nav_bar.dart` and this file
/// under the 400-line budget.
abstract final class NavBarConstants {
  // ── Dimensions ──────────────────────────────────────────────
  static const double tabHeight = 48.0;
  static const double tabHorizontalPadding = 18.0;
  static const double tabRadius = 14.0;
  static const double iconSize = 24.0;
  static const double iconLabelGap = 9.0;

  // ── Badge ───────────────────────────────────────────────────
  static const double badgeMinWidth = 17.0;
  static const double badgeHeight = 17.0;
  static const double badgeFontSize = 9.0;
  static const double badgeBorderWidth = 1.5;
  static const double badgeHorizontalPadding = 3.0;

  // ── Colors ──────────────────────────────────────────────────

  /// Glass background: rgba(255,252,248,0.78).
  static const Color glassBackground = Color(0xC8FFFCF8);

  /// Glass border: rgba(255,255,255,0.84).
  static const Color glassBorder = Color(0xD6FFFFFF);

  // ── Gradients ───────────────────────────────────────────────

  /// Active pill: 158deg, #F07020 -> #DF5C08.
  static const LinearGradient activePillGradient = LinearGradient(
    begin: Alignment(-0.37, -0.93),
    end: Alignment(0.37, 0.93),
    colors: [Color(0xFFF07020), Color(0xFFDF5C08)],
  );

  /// Badge: 135deg, #E8650A -> #C9510A.
  static const LinearGradient badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8650A), Color(0xFFC9510A)],
  );

  // ── Shadows ─────────────────────────────────────────────────

  /// Pill shadow: 0 4px 22px rgba(224,92,8,0.44).
  static const BoxShadow pillShadow = BoxShadow(
    color: Color(0x70E05C08),
    blurRadius: 22,
    offset: Offset(0, 4),
  );

  /// Container shadow: 0 18px 60px rgba(230,126,34,0.14).
  static const BoxShadow containerOuterShadow = BoxShadow(
    color: Color(0x24E67E22),
    blurRadius: 60,
    offset: Offset(0, 18),
  );

  // ── Timing ──────────────────────────────────────────────────

  /// Tandy pulse ring cycle: 3.4 s.
  static const Duration tandyPulseDuration = Duration(milliseconds: 3400);

  /// Stagger delay between consecutive tab entrances.
  static const Duration staggerDelay = Duration(milliseconds: 55);

  /// Delay before the first tab starts its entrance.
  static const Duration entranceInitialDelay = Duration(milliseconds: 140);

  /// Duration of the active-pill morph animation.
  static const Duration pillAnimationDuration = Duration(milliseconds: 340);
}

// ── NavActiveBloomHalo ──────────────────────────────────────────────────────

/// Radial orange glow rendered behind the active pill to create
/// the ambient "bloom" signature from the web design.
class NavActiveBloomHalo extends StatelessWidget {
  const NavActiveBloomHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NavBarConstants.tabRadius + 4),
          gradient: RadialGradient(
            center: const Alignment(0.0, 0.88),
            radius: 0.78,
            colors: [
              const Color(0xFFF07020).withValues(alpha: 0.30),
              const Color(0xFFF07020).withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.70],
          ),
        ),
      ),
    );
  }
}

// ── NavUnreadBadge ──────────────────────────────────────────────────────────

/// Gradient pill badge showing an unread count (capped at "99+").
class NavUnreadBadge extends StatelessWidget {
  const NavUnreadBadge({required this.count, super.key});

  /// Number of unread items. Values above 99 display as "99+".
  final int count;

  @override
  Widget build(BuildContext context) {
    final String displayLabel = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(
        minWidth: NavBarConstants.badgeMinWidth,
        minHeight: NavBarConstants.badgeHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: NavBarConstants.badgeHorizontalPadding,
      ),
      decoration: BoxDecoration(
        gradient: NavBarConstants.badgeGradient,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.95),
          width: NavBarConstants.badgeBorderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        displayLabel,
        style: const TextStyle(
          fontSize: NavBarConstants.badgeFontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.textInverse,
          height: 1,
        ),
      ),
    );
  }
}

// ── NavTabEntrance ──────────────────────────────────────────────────────────

/// Staggered slide-up + scale + fade entrance wrapper for individual tabs.
///
/// Each tab receives a different [delay] to produce the 55 ms stagger
/// fan-in described in the web spec.
class NavTabEntrance extends StatelessWidget {
  const NavTabEntrance({
    required this.delay,
    required this.entranceController,
    required this.child,
    super.key,
  });

  /// Offset from the start of the entrance controller at which this tab
  /// begins its animation.
  final Duration delay;

  /// Shared controller that drives the entire entrance sequence.
  final AnimationController entranceController;

  /// The tab widget to animate in.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int totalMs = entranceController.duration?.inMilliseconds ?? 1;
    final double startFraction = delay.inMilliseconds / totalMs;
    final double endFraction =
        ((delay.inMilliseconds + 300) / totalMs).clamp(0.0, 1.0);

    final Animation<double> opacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: entranceController,
        curve: Interval(startFraction, endFraction, curve: Curves.easeOut),
      ),
    );

    final Animation<Offset> slide =
        Tween<Offset>(begin: const Offset(0, 14), end: Offset.zero).animate(
      CurvedAnimation(
        parent: entranceController,
        curve:
            Interval(startFraction, endFraction, curve: Curves.easeOutBack),
      ),
    );

    final Animation<double> scale =
        Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: entranceController,
        curve:
            Interval(startFraction, endFraction, curve: Curves.easeOutBack),
      ),
    );

    return AnimatedBuilder(
      animation: entranceController,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value,
          child: Transform.translate(
            offset: slide.value,
            child: Transform.scale(
              scale: scale.value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ── NavBokehOrbs ────────────────────────────────────────────────────────────

/// Three warm atmospheric light pools drifting behind the nav bar:
/// orange (200x110, blur 32), teal (150x85, blur 26), gold (130x75, blur 24).
class NavBokehOrbs extends StatelessWidget {
  const NavBokehOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 8,
            width: 200,
            height: 110,
            child: _BokehOrb(
              color: const Color(0xFFF07E22).withValues(alpha: 0.22),
              blurSigma: 32,
            ),
          ),
          Positioned(
            left: 120,
            top: 12,
            width: 150,
            height: 85,
            child: _BokehOrb(
              color: AppColors.secondary.withValues(alpha: 0.17),
              blurSigma: 26,
            ),
          ),
          Positioned(
            right: 20,
            top: 10,
            width: 130,
            height: 75,
            child: _BokehOrb(
              color: const Color(0xFFFFB932).withValues(alpha: 0.14),
              blurSigma: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single blurred radial-gradient ellipse used as a bokeh light pool.
class _BokehOrb extends StatelessWidget {
  const _BokehOrb({
    required this.color,
    required this.blurSigma,
  });

  final Color color;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
        tileMode: TileMode.decal,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
            stops: const [0.0, 0.68],
          ),
        ),
      ),
    );
  }
}

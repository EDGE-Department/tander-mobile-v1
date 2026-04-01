import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';

// ── Tab descriptor ──────────────────────────────────────────────────────────

/// Immutable descriptor for a single navigation tab.
@immutable
class NavTabDescriptor {
  const NavTabDescriptor({
    required this.id,
    required this.label,
    required this.route,
    this.iconAsset,
    this.iconData,
    this.activeIconData,
    this.iconColor,
    this.isTandy = false,
  }) : assert(iconAsset != null || iconData != null,
            'Either iconAsset or iconData must be provided');

  /// Unique identifier used for badge resolution.
  final String id;

  /// Human-readable label displayed beneath the icon.
  final String label;

  /// GoRouter path for this tab.
  final String route;

  /// Asset path to the tab icon image (null if using iconData).
  final String? iconAsset;

  /// Icon data for vector icon (null if using iconAsset).
  final IconData? iconData;

  /// Filled variant for active state (null = use same icon).
  final IconData? activeIconData;

  /// Custom color for the icon when inactive (null = default tint).
  final Color? iconColor;

  /// Whether this tab represents the Tandy AI companion.
  final bool isTandy;

  /// Whether this tab uses a vector icon instead of an image asset.
  bool get usesIconData => iconData != null;
}

// ── Design constants ────────────────────────────────────────────────────────

/// Pixel-spec constants extracted from the web MobileBottomDock.
abstract final class NavBarConstants {
  // ── Dimensions (mobile dock) ─────────────────────────────────
  static const double dockBorderRadius = 28.0;
  static const double dockMargin = 12.0; // mx-3 mb-3 = 12px
  static const double tabMinSize = 58.0; // min-h 58px min-w 58px
  static const double tabBorderRadius = 18.0; // rounded-[18px]
  static const double iconContainerSize = 30.0; // w-[30px] h-[30px]
  static const double iconSize = 25.0; // iconSize + 4 from web
  static const double iconLabelGap = 3.0; // gap-[3px]
  static const double tabPaddingH = 16.0; // wider pill to match web
  static const double tabPaddingV = 10.0; // taller pill to match web

  // ── Dimensions (tablet rail) ─────────────────────────────────
  static const double railWidth = 72.0;
  static const double railTabSize = 56.0;

  // ── Badge ───────────────────────────────────────────────────
  static const double badgeMinWidth = 17.0;
  static const double badgeHeight = 17.0;
  static const double badgeFontSize = 9.0;
  static const double badgeBorderWidth = 1.5;
  static const double badgeHorizontalPadding = 3.0;

  // ── Glass (mobile dock) ──────────────────────────────────────
  /// Mobile dock background: rgba(255,252,248,0.97).
  static const Color dockBackground = Color(0x00000000); // transparent

  /// Mobile dock border: rgba(255,255,255,0.92).
  static const Color dockBorder = Color(0x20DDD3C2); // subtle warm border

  /// Backdrop blur sigma for mobile dock (48px CSS → ~24 sigma).
  static const double dockBlurSigma = 24.0;

  // ── Glass (tablet rail) ──────────────────────────────────────
  /// Rail background: rgba(255,252,248,0.78).
  static const Color railBackground = Color(0xC8FFFCF8);

  /// Rail border: rgba(255,255,255,0.84).
  static const Color railBorder = Color(0xD6FFFFFF);

  static const double railBlurSigma = 32.0;

  // ── Organic blob pill ────────────────────────────────────────

  /// Active pill border radius — organic irregular shape.
  /// Web: 16px 13px 14px 15px / 15px 16px 13px 14px.
  static const BorderRadius activePillBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(18),
    bottomRight: Radius.circular(19),
    bottomLeft: Radius.circular(20),
  );

  /// Active pill: 158deg, #F07020 → #DF5C08.
  static const LinearGradient activePillGradient = LinearGradient(
    begin: Alignment(-0.37, -0.93),
    end: Alignment(0.37, 0.93),
    colors: [Color(0xFFF07020), Color(0xFFDF5C08)],
  );

  /// Badge: 135deg, #E8650A → #C9510A.
  static const LinearGradient badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8650A), Color(0xFFC9510A)],
  );

  // ── Shadows ─────────────────────────────────────────────────

  /// Active pill shadow: 0 4px 22px rgba(224,92,8,0.44),
  /// 0 1px 4px rgba(224,92,8,0.20).
  static const List<BoxShadow> activePillShadows = [
    BoxShadow(
      color: Color(0x80E05C08),
      blurRadius: 24,
      offset: Offset(0, 6),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Color(0x40E05C08),
      blurRadius: 6,
      offset: Offset(0, 1),
    ),
  ];

  /// Mobile dock box shadow.
  static const List<BoxShadow> dockShadows = [
    BoxShadow(
      color: Color(0x25000000),
      blurRadius: 20,
      offset: Offset(0, -4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 6,
      offset: Offset(0, -1),
    ),
    BoxShadow(
      color: Color(0x1C000000),
      blurRadius: 40,
      offset: Offset(0, 8),
    ),
  ];

  // ── Timing ──────────────────────────────────────────────────

  /// Tandy pulse ring cycle: 3.4 s.
  static const Duration tandyPulseDuration = Duration(milliseconds: 3400);

  /// Stagger delay between consecutive tab entrances.
  static const Duration staggerDelay = Duration(milliseconds: 55);

  /// Delay before the first tab starts its entrance.
  static const Duration entranceInitialDelay = Duration(milliseconds: 140);

  /// Duration of the active-pill morph animation.
  static const Duration pillAnimationDuration = Duration(milliseconds: 340);

  /// Logo heartbeat cycle: 4.5 s.
  static const Duration logoHeartbeatDuration = Duration(milliseconds: 4500);
}

// ── NavActiveBloomHalo ──────────────────────────────────────────────────────

/// Radial orange glow rendered behind the active pill.
/// Web: radial-gradient(ellipse 78% 68% at 50% 88%,
///       rgba(240,112,32,0.30), transparent 70%) blur(12px).
class NavActiveBloomHalo extends StatelessWidget {
  const NavActiveBloomHalo({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
          tileMode: TileMode.decal,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(NavBarConstants.tabBorderRadius + 4),
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
      ),
    );
  }
}

// ── NavUnreadBadge ──────────────────────────────────────────────────────────

/// Gradient pill badge showing an unread count (capped at "99+").
class NavUnreadBadge extends StatelessWidget {
  const NavUnreadBadge({required this.count, super.key});

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

/// Staggered slide-up + scale + fade entrance for individual tabs.
/// Each tab receives a different [delay] for the 55 ms stagger fan-in.
class NavTabEntrance extends StatelessWidget {
  const NavTabEntrance({
    required this.delay,
    required this.entranceController,
    required this.child,
    super.key,
  });

  final Duration delay;
  final AnimationController entranceController;
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

/// Three warm atmospheric light pools behind the nav bar.
/// Orange 200x110 blur(32), teal 150x85 blur(26), gold 130x75 blur(24).
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

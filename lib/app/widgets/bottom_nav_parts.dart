import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';

// ── Tab descriptor ──────────────────────────────────────────────────────────

/// Immutable descriptor for a single navigation tab.
///
/// Shared by the phone bottom dock ([TanderBottomNavBar]) and the
/// tablet/desktop header ([TanderTopNavBar]).
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
  }) : assert(
         iconAsset != null || iconData != null,
         'Either iconAsset or iconData must be provided',
       );

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

// ── Badge constants ─────────────────────────────────────────────────────────

/// Pixel-spec constants for the unread-count badge.
abstract final class NavBarConstants {
  static const double badgeMinWidth = 17.0;
  static const double badgeHeight = 17.0;
  static const double badgeFontSize = 9.0;
  static const double badgeBorderWidth = 1.5;
  static const double badgeHorizontalPadding = 3.0;

  /// Badge: 135deg, #E8650A → #C9510A.
  static const LinearGradient badgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8650A), Color(0xFFC9510A)],
  );
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

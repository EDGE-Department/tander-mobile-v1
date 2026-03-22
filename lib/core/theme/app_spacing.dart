/// Centralized spacing scale for the Tander design system.
///
/// All padding, margin, and gap values must reference these tokens.
/// The scale is intentionally limited to enforce visual consistency.
abstract final class AppSpacing {
  // ── Scale ──────────────────────────────────────────────────

  /// 4 logical pixels.
  static const double xxs = 4;

  /// 8 logical pixels.
  static const double xs = 8;

  /// 12 logical pixels.
  static const double sm = 12;

  /// 16 logical pixels — the base unit.
  static const double md = 16;

  /// 24 logical pixels.
  static const double lg = 24;

  /// 32 logical pixels.
  static const double xl = 32;

  /// 48 logical pixels.
  static const double xxl = 48;

  /// 64 logical pixels.
  static const double xxxl = 64;

  // ── Touch targets (WCAG / elder-friendly) ──────────────────

  /// WCAG 2.2 minimum touch-target size (44 x 44).
  static const double touchMinimum = 44;

  /// Recommended comfortable touch-target size for seniors.
  static const double touchComfortable = 56;
}

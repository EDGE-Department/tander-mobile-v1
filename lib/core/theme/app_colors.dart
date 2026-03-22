import 'dart:ui';

/// Centralized color tokens for the Tander design system.
///
/// Derived from the web CSS variables to ensure visual parity
/// across platforms. Every color used in the app must reference
/// a token from this class — no inline hex literals elsewhere.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────

  /// Primary orange used for CTAs, highlights, and branding.
  static const Color primary = Color(0xFFE67E22);

  /// Darkened primary for pressed / hover states.
  static const Color primaryHover = Color(0xFFD35400);

  /// Very light orange tint for backgrounds and chips.
  static const Color primaryLight = Color(0xFFFEF3E2);

  /// WCAG-contrast-safe variant of primary for text-on-white.
  static const Color primaryAccessible = Color(0xFFCF6F1E);

  /// Secondary teal for complementary accents.
  static const Color secondary = Color(0xFF0F9D94);

  /// Darkened secondary for pressed / hover states.
  static const Color secondaryHover = Color(0xFF0D8A82);

  /// Very light teal tint for backgrounds and chips.
  static const Color secondaryLight = Color(0xFFE6F7F6);

  // ── Surfaces ───────────────────────────────────────────────

  /// Warm off-white page background.
  static const Color canvas = Color(0xFFFAF8F5);

  /// Default card / sheet surface.
  static const Color card = Color(0xFFFFFFFF);

  /// Subtle warm background for grouped sections.
  static const Color subtle = Color(0xFFF5F1EC);

  // ── Text ───────────────────────────────────────────────────

  /// Highest-contrast text (headings, labels).
  static const Color textStrong = Color(0xFF1F2937);

  /// Default body copy.
  static const Color textBody = Color(0xFF4B5563);

  /// De-emphasized helper text.
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Disabled / placeholder text.
  static const Color textDisabled = Color(0xFFD1D5DB);

  /// Text rendered on dark or primary backgrounds.
  static const Color textInverse = Color(0xFFFFFFFF);

  // ── Borders ────────────────────────────────────────────────

  /// Default border / divider.
  static const Color border = Color(0xFFE5E1DC);

  /// Lighter border for subtle separation.
  static const Color borderLight = Color(0xFFEDE8E0);

  // ── Semantic ───────────────────────────────────────────────

  /// Success green.
  static const Color success = Color(0xFF22C55E);

  /// Light success background.
  static const Color successLight = Color(0xFFF0FDF4);

  /// Danger / error red.
  static const Color danger = Color(0xFFEF4444);

  /// Light danger background.
  static const Color dangerLight = Color(0xFFFEF2F2);

  /// Warning amber.
  static const Color warning = Color(0xFFF59E0B);

  /// Light warning background.
  static const Color warningLight = Color(0xFFFFFBEB);

  /// Informational blue.
  static const Color info = Color(0xFF3B82F6);

  /// Light info background.
  static const Color infoLight = Color(0xFFEFF6FF);

  // ── Special ────────────────────────────────────────────────

  /// Dark warm tone for call screens and dark sections.
  static const Color darkWarm = Color(0xFF1A0800);

  /// 40 % black overlay for modals and scrims.
  static const Color overlay = Color(0x66000000);
}

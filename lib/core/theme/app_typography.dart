import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Centralized typography tokens for the Tander design system.
///
/// Two font families mirror the web app:
///   - **Bricolage Grotesque** for display headings (warm, rounded).
///   - **Plus Jakarta Sans** for body text (clean, highly legible).
///
/// Elder-friendly: the smallest content style ([bodySm]) is 14 px.
/// Never use anything smaller for user-facing text.
abstract final class AppTypography {
  // ── Font families ────────────────────────────────────────────

  /// Bricolage Grotesque family string for ThemeData overrides.
  static String get displayFontFamily =>
      GoogleFonts.bricolageGrotesque().fontFamily!;

  /// Plus Jakarta Sans family string for ThemeData overrides.
  static String get bodyFontFamily =>
      GoogleFonts.plusJakartaSans().fontFamily!;

  // ── Brand wordmark (script/chancery) ─────────────────────────

  /// Calligraphic italic script matching the web's `font-chancery`
  /// (Apple Chancery). Used for the "Tander" wordmark throughout the app.
  /// Satisfy is the closest Google Fonts match to Apple Chancery's
  /// calligraphic italic style.
  static TextStyle brandWordmark({
    double fontSize = 24,
    Color color = AppColors.textStrong,
    double letterSpacing = -0.5,
  }) =>
      GoogleFonts.satisfy(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: letterSpacing,
        height: 1.0,
      );

  // ── Display styles (Bricolage Grotesque) ─────────────────────

  /// 48 px — hero banners, splash headings.
  static TextStyle get displayXl => GoogleFonts.bricolageGrotesque(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.04 * 48,
        color: AppColors.textStrong,
      );

  /// 36 px — section hero titles.
  static TextStyle get displayLg => GoogleFonts.bricolageGrotesque(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.03 * 36,
        color: AppColors.textStrong,
      );

  /// 30 px — page-level headings.
  static TextStyle get h1 => GoogleFonts.bricolageGrotesque(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.02 * 30,
        color: AppColors.textStrong,
      );

  /// 24 px — card or section headings.
  static TextStyle get h2 => GoogleFonts.bricolageGrotesque(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.02 * 24,
        color: AppColors.textStrong,
      );

  /// 20 px — sub-section headings.
  static TextStyle get h3 => GoogleFonts.bricolageGrotesque(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.01 * 20,
        color: AppColors.textStrong,
      );

  // ── Body styles (Plus Jakarta Sans) ──────────────────────────

  /// 18 px — large body / lead paragraphs.
  static TextStyle get bodyLg => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textBody,
      );

  /// 16 px — default body copy.
  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.textBody,
      );

  /// 14 px — compact body. Smallest size allowed for content text.
  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textBody,
      );

  /// 14 px semibold — form labels, chip text, button labels.
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textStrong,
      );

  /// 12 px medium — timestamps, helper hints, non-critical metadata.
  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textMuted,
      );

  /// 14 px monospace — code snippets, IDs, debug info.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textBody,
      );
}

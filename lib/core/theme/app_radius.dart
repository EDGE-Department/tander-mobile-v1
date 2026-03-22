import 'package:flutter/painting.dart';

/// Border-radius tokens for the Tander design system.
///
/// Exposes both raw `double` values (for custom shapes, clip rects,
/// etc.) and pre-built [BorderRadius] constants for direct use in
/// container decorations.
abstract final class AppRadius {
  // ── Raw doubles ────────────────────────────────────────────

  /// 4 logical pixels.
  static const double xs = 4.0;

  /// 8 logical pixels.
  static const double sm = 8.0;

  /// 12 logical pixels.
  static const double md = 12.0;

  /// 16 logical pixels.
  static const double lg = 16.0;

  /// 24 logical pixels.
  static const double xl = 24.0;

  /// 32 logical pixels.
  static const double xxl = 32.0;

  /// Effectively circular — use for pills and avatars.
  static const double full = 999.0;

  // ── BorderRadius constants ─────────────────────────────────

  /// BorderRadius with 4 px circular corners.
  static final BorderRadius borderXs = BorderRadius.circular(xs);

  /// BorderRadius with 8 px circular corners.
  static final BorderRadius borderSm = BorderRadius.circular(sm);

  /// BorderRadius with 12 px circular corners.
  static final BorderRadius borderMd = BorderRadius.circular(md);

  /// BorderRadius with 16 px circular corners.
  static final BorderRadius borderLg = BorderRadius.circular(lg);

  /// BorderRadius with 24 px circular corners.
  static final BorderRadius borderXl = BorderRadius.circular(xl);

  /// BorderRadius with 32 px circular corners.
  static final BorderRadius borderXxl = BorderRadius.circular(xxl);

  /// Fully circular BorderRadius — pills, avatars, FABs.
  static final BorderRadius borderFull = BorderRadius.circular(full);
}

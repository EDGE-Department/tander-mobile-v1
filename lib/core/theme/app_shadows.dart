import 'package:flutter/painting.dart';

/// Warm box-shadow tokens for the Tander design system.
///
/// Every shadow uses the primary orange hue at varying opacities
/// to maintain the warm visual language across elevation levels.
abstract final class AppShadows {
  /// Extra-small warm shadow — subtle lift for chips and badges.
  static const List<BoxShadow> warmXs = [
    BoxShadow(
      color: Color(0x0FE67E22),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Small warm shadow — cards at rest.
  static const List<BoxShadow> warmSm = [
    BoxShadow(
      color: Color(0x14E67E22),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium warm shadow — raised cards, popovers.
  static const List<BoxShadow> warmMd = [
    BoxShadow(
      color: Color(0x1AE67E22),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Large warm shadow — floating action buttons, sheets.
  static const List<BoxShadow> warmLg = [
    BoxShadow(
      color: Color(0x1FE67E22),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Extra-large warm shadow — modals, dialogs.
  static const List<BoxShadow> warmXl = [
    BoxShadow(
      color: Color(0x24E67E22),
      blurRadius: 56,
      offset: Offset(0, 24),
    ),
  ];
}

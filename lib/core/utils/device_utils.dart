/// Device detection utilities.
///
/// Provides static methods for identifying device form factors (phone vs.
/// tablet) and configuring appropriate orientation constraints.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tablet detection threshold in logical pixels (shortestSide > 600dp).
const double _tabletBreakpoint = 600;

abstract final class DeviceUtils {
  /// Returns `true` when the device's shortest side exceeds 600 dp,
  /// indicating a tablet or large-screen device.
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    return shortestSide > _tabletBreakpoint;
  }

  /// Sets preferred orientations based on device type:
  /// - **Phones**: portrait only (up + down).
  /// - **Tablets**: all orientations (portrait + landscape).
  static Future<void> configureOrientations(BuildContext context) async {
    if (isTablet(context)) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
}

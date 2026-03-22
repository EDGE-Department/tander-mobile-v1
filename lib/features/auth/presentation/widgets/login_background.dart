import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Full-bleed gradient background for the login screen.
///
/// Linear gradient from [AppColors.primaryLight] (top-left) to
/// [AppColors.secondaryLight] (bottom-right), matching the web's
/// `--gradient-auth-bg`.
class LoginGradientBackground extends StatelessWidget {
  const LoginGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
          ),
        ),
      ),
    );
  }
}

/// Three subtle, translucent floating orbs that add depth to the
/// gradient background — matching the web's decorative blobs.
///
/// Wrapped in [IgnorePointer] so they never intercept taps.
class LoginDecorativeOrbs extends StatelessWidget {
  const LoginDecorativeOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: Stack(
        children: [
          _Orb(
            diameter: screenSize.width * 0.55,
            color: AppColors.primary.withValues(alpha: 0.08),
            top: -screenSize.width * 0.12,
            left: -screenSize.width * 0.15,
          ),
          _Orb(
            diameter: screenSize.width * 0.4,
            color: AppColors.secondary.withValues(alpha: 0.06),
            bottom: screenSize.height * 0.15,
            right: -screenSize.width * 0.1,
          ),
          _Orb(
            diameter: screenSize.width * 0.3,
            color: AppColors.primary.withValues(alpha: 0.05),
            bottom: -screenSize.width * 0.08,
            left: screenSize.width * 0.2,
          ),
        ],
      ),
    );
  }
}

/// Single translucent circular gradient orb positioned absolutely.
class _Orb extends StatelessWidget {
  const _Orb({
    required this.diameter,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double diameter;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

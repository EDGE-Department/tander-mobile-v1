import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/splash/presentation/widgets/splash_painters.dart';

/// Animated constellation for the login & auth screens.
///
/// Uses the same web-exact `SplashConstellationPainter` (19 star nodes,
/// 1200x900 viewBox with "cover" mapping) to ensure visual parity
/// with the web's `LoginConstellationSVG`.
class LoginConstellation extends StatefulWidget {
  const LoginConstellation({super.key});

  @override
  State<LoginConstellation> createState() => _LoginConstellationState();
}

class _LoginConstellationState extends State<LoginConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.45,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, _) => CustomPaint(
              painter: SplashConstellationPainter(_controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

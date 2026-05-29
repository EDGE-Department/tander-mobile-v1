import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Real-time availability status for email/phone text fields.
enum AvailabilityStatus { idle, checking, available, taken }

/// Suffix icon that reflects the current [AvailabilityStatus] of a field.
class AvailabilitySuffixIcon extends StatelessWidget {
  final AvailabilityStatus status;

  const AvailabilitySuffixIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) => switch (status) {
    AvailabilityStatus.idle => const SizedBox.shrink(),
    AvailabilityStatus.checking => const Padding(
      padding: EdgeInsets.only(right: 12),
      child: _PulsingDotsLoader(),
    ),
    AvailabilityStatus.available => const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Icon(
        PhosphorIconsRegular.checkCircle,
        color: AppColors.secondary,
        size: 24,
      ),
    ),
    AvailabilityStatus.taken => const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Icon(
        PhosphorIconsRegular.xCircle,
        color: Color(0xFFEF4444),
        size: 24,
      ),
    ),
  };
}

/// Three dots that fade in sequence, giving a smooth "checking..." feel.
class _PulsingDotsLoader extends StatefulWidget {
  const _PulsingDotsLoader();

  @override
  State<_PulsingDotsLoader> createState() => _PulsingDotsLoaderState();
}

class _PulsingDotsLoaderState extends State<_PulsingDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Driving is gated in build() on MediaQuery.disableAnimationsOf, which is
    // unavailable here in initState.
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Vestibular accessibility: when reduce-motion is on, show static
    // full-opacity dots and stop driving the pulse.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    return SizedBox(
      width: 28,
      height: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Each dot peaks at a different phase offset
            final delay = i * 0.25;
            final t = (_controller.value - delay) % 1.0;
            // Smooth bell-curve opacity: peak at 0.15, fade by 0.5
            final opacity = reduceMotion
                ? 1.0
                : t < 0.5
                ? (t * 2.0).clamp(0.0, 1.0) * 0.7 + 0.3
                : ((1.0 - t) * 2.0).clamp(0.0, 1.0) * 0.7 + 0.3;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

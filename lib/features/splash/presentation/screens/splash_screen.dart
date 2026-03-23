import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';

/// Minimum splash display duration matching the web SessionBootstrapProvider.
const Duration _minimumSplashDuration = Duration(seconds: 2);

/// Animated splash screen shown during cold-start session bootstrap.
///
/// Design:
///   - Full-screen dark warm gradient (145 deg, #1A0800 to #0D1B2A).
///   - Centered Tander logo with scale-overshoot entrance.
///   - "Tander" wordmark with fade-up entrance.
///   - Two breathing pulse rings behind the logo (orange + teal).
///
/// Behavior:
///   - Triggers [AuthNotifier.bootstrap] on mount.
///   - Enforces a 2-second minimum display so entrance animations play fully.
///   - GoRouter redirect handles navigation once auth state resolves.
final class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // -- Animation controllers ------------------------------------------------

  late final AnimationController _logoController;
  late final AnimationController _wordmarkController;
  late final AnimationController _pulseController;

  // -- Derived animations ---------------------------------------------------

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceSequence();
    // Schedule bootstrap after the first frame to avoid modifying providers
    // during the widget tree build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerBootstrap();
    });
  }

  void _initializeAnimations() {
    // Logo: scale from 0.85 to 1.0 with spring overshoot over 800ms.
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const _SpringOvershootCurve(),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Wordmark: fade-up from 8px below over 600ms, delayed 400ms.
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _wordmarkController,
        curve: Curves.easeOut,
      ),
    );

    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0.0, 8.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _wordmarkController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Pulse rings: repeating scale + fade over 2.4s.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  void _startEntranceSequence() {
    // Logo starts immediately.
    _logoController.forward();

    // Wordmark enters 400ms later.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _wordmarkController.forward();
    });

    // Pulse rings repeat indefinitely.
    _pulseController.repeat();
  }

  void _triggerBootstrap() {
    // Minimum splash timer runs in parallel with bootstrap.
    final minimumTimer = Future<void>.delayed(_minimumSplashDuration);

    // Fire bootstrap -- auth state change triggers GoRouter redirect.
    // Timeout after 10s so the splash never hangs forever if backend is down.
    final bootstrapFuture = ref
        .read(authNotifierProvider.notifier)
        .bootstrap()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Force unauthenticated on timeout so user sees login screen
            ref.read(authNotifierProvider.notifier).forceUnauthenticated();
          },
        );

    // Both must complete; GoRouter redirect handles navigation automatically.
    Future.wait<void>([minimumTimer, bootstrapFuture]);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _wordmarkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0800), // Dark warm
              Color(0xFF0D1B2A), // Deep navy
            ],
            transform: GradientRotation(145 * math.pi / 180),
          ),
        ),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulseRingsWithLogo(),
              const SizedBox(height: AppSpacing.lg),
              _buildWordmark(),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo at center with two expanding/fading pulse rings behind it.
  Widget _buildPulseRingsWithLogo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring (orange, no phase offset).
          _PulseRing(
            controller: _pulseController,
            color: AppColors.primary,
            phaseOffset: 0.0,
          ),
          // Inner pulse ring (teal, offset by half cycle).
          _PulseRing(
            controller: _pulseController,
            color: AppColors.secondary,
            phaseOffset: 0.5,
          ),
          // Logo with scale-overshoot entrance.
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: child,
                ),
              );
            },
            child: Image.asset(
              'assets/icons/tander_logo.png',
              width: 64,
              height: 64,
              semanticLabel: 'Tander logo',
            ),
          ),
        ],
      ),
    );
  }

  /// Wordmark with fade-up entrance animation.
  Widget _buildWordmark() {
    return AnimatedBuilder(
      animation: _wordmarkController,
      builder: (context, child) {
        return Opacity(
          opacity: _wordmarkOpacity.value,
          child: Transform.translate(
            offset: _wordmarkSlide.value,
            child: child,
          ),
        );
      },
      child: Text(
        'Tander',
        style: AppTypography.displayLg.copyWith(
          color: AppColors.textInverse,
          letterSpacing: -1.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulse ring -- expanding + fading ring animation
// ---------------------------------------------------------------------------

/// A single breathing pulse ring that expands and fades out on repeat.
///
/// [phaseOffset] staggers multiple rings so they do not overlap visually.
/// Value must be between 0.0 and 1.0 (fraction of the animation cycle).
class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.controller,
    required this.color,
    required this.phaseOffset,
  });

  final AnimationController controller;
  final Color color;
  final double phaseOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Offset the animation progress to stagger rings.
        final progress = (controller.value + phaseOffset) % 1.0;

        // Scale from 0.4 to 1.0 of the container.
        final scale = 0.4 + (progress * 0.6);

        // Fade out as the ring expands: full opacity at start, gone at end.
        final opacity = (1.0 - progress).clamp(0.0, 0.4);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Spring overshoot curve
// ---------------------------------------------------------------------------

/// Custom curve that overshoots the target by ~8% before settling.
///
/// Simulates a spring with slight bounce for a premium feel.
class _SpringOvershootCurve extends Curve {
  const _SpringOvershootCurve();

  @override
  double transformInternal(double t) {
    // Spring-like overshoot: peaks ~8% past 1.0 at about t=0.7, then settles.
    const overshootAmount = 1.08;
    if (t < 0.7) {
      // Ease out to overshoot.
      final normalized = t / 0.7;
      return overshootAmount * _easeOut(normalized);
    }
    // Settle back from overshoot to 1.0.
    final normalized = (t - 0.7) / 0.3;
    return overshootAmount - (overshootAmount - 1.0) * _easeInOut(normalized);
  }

  double _easeOut(double t) => 1.0 - math.pow(1.0 - t, 3).toDouble();

  double _easeInOut(double t) {
    return t < 0.5
        ? 2.0 * t * t
        : 1.0 - math.pow(-2.0 * t + 2.0, 2).toDouble() / 2.0;
  }
}

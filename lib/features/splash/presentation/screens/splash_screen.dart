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
            begin: Alignment(-0.7, -0.5),
            end: Alignment(0.7, 0.5),
            colors: [
              Color(0xFFE8734A), // Warm coral-orange
              Color(0xFFCD6038), // Deep burnt orange
              Color(0xFF2A7A74), // Muted dark teal
              Color(0xFF0F9D94), // Teal
            ],
            stops: [0.0, 0.32, 0.62, 1.0],
          ),
        ),
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Constellation stars
              const _SplashConstellation(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPulseRingsWithLogo(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildWordmark(),
                    const SizedBox(height: 8),
                    const Text(
                      'Made for Filipino seniors 60+',
                      style: TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
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
          // Outer pulse ring (white, no phase offset).
          _PulseRing(
            controller: _pulseController,
            color: Colors.white,
            phaseOffset: 0.0,
          ),
          // Inner pulse ring (white, offset by half cycle).
          _PulseRing(
            controller: _pulseController,
            color: Colors.white,
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
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.white.withAlpha(60), blurRadius: 20, spreadRadius: 4)],
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/icons/tander_logo.png',
                semanticLabel: 'Tander logo',
              ),
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
        style: AppTypography.brandWordmark().copyWith(
          fontSize: 36,
          color: Colors.white,
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

/// Subtle constellation stars + lines for the splash background.
class _SplashConstellation extends StatefulWidget {
  const _SplashConstellation();

  @override
  State<_SplashConstellation> createState() => _SplashConstellationState();
}

class _SplashConstellationState extends State<_SplashConstellation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(painter: _ConstellationPainter(_controller.value), size: Size.infinite),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter(this.time);
  final double time;

  // Web star positions normalized from 1200x700 viewBox
  static const _stars = <List<double>>[
    [0.067, 0.171], [0.150, 0.357], [0.050, 0.571], [0.208, 0.243],
    [0.250, 0.657], [0.350, 0.429], [0.450, 0.486], [0.500, 0.500],
    [0.550, 0.486], [0.650, 0.429], [0.750, 0.243], [0.792, 0.400],
    [0.867, 0.600], [0.917, 0.200], [0.933, 0.714], [0.292, 0.129],
    [0.500, 0.157], [0.708, 0.129], [0.142, 0.136], [0.858, 0.157],
  ];

  static const _radii = <double>[2.2,1.6,2.8,1.8,1.4,1.8,2.2,4.5,2.2,1.8,1.8,2.2,2.8,1.6,1.8,1.4,1.8,1.4,1.8,1.4];

  // Colors: warm orange left, white center, teal right
  static const _colors = <int>[
    0xD9FFA05A, 0xB3FFFFFF, 0xCCFFB464, 0xA6FFFFFF, 0x80FFFFFF,
    0xA6FFFFFF, 0xBFFFFFFF, 0xFFFFFFFF, 0xBFFFFFFF, 0xA6FFFFFF,
    0xCC96E6E1, 0xD978DCD7, 0xCC64D2CD, 0xA6FFFFFF, 0x80FFFFFF,
    0x80FFFFFF, 0x99FFFFFF, 0x80FFFFFF, 0xA6FFB464, 0xA696E6E1,
  ];

  static const _edges = [[0,1],[1,2],[2,4],[0,3],[3,5],[4,5],[5,6],[8,9],[9,11],[10,11],[11,12],[12,14],[10,13],[18,15],[15,16],[16,17],[17,19],[3,15],[16,8],[17,13]];
  static const _bridges = [[6,7],[7,8]];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = time * math.pi * 2;

    // Vignette
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()
      ..shader = RadialGradient(colors: [Colors.transparent, Colors.black.withAlpha(77)], radius: 0.75).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Nebulae
    _drawNebula(canvas, size, 0.17, 0.43, 0.20, const Color(0x40FF8C3C), t * 0.5);
    _drawNebula(canvas, size, 0.82, 0.49, 0.20, const Color(0x3300C8C0), t * 0.43 + 2);

    // Edges
    for (final e in _edges) { canvas.drawLine(_p(e[0], size), _p(e[1], size), Paint()..color = const Color(0x1AFFFFFF)..strokeWidth = 0.6); }

    // Bridge edges — pulsing
    for (final e in _bridges) {
      final pulse = 0.20 + 0.40 * ((math.sin(t * 1.5) + 1) / 2);
      canvas.drawLine(_p(e[0], size), _p(e[1], size), Paint()..color = Color.fromRGBO(255, 255, 255, pulse.clamp(0.0, 1.0))..strokeWidth = 1.0..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6));
    }

    // Energy orbs
    for (int i = 0; i < 8; i++) {
      const paths = [[0,1],[3,5],[6,7],[7,8],[10,11],[11,12],[15,16],[16,8]];
      final from = _p(paths[i][0], size); final to = _p(paths[i][1], size);
      final prog = (time + i * 0.125) % 1.0;
      final pos = Offset.lerp(from, to, prog)!;
      final fade = (prog / 0.08).clamp(0.0, 1.0) * ((1.0 - prog) / 0.08).clamp(0.0, 1.0);
      if (fade > 0.02) {
        final c = paths[i][0] >= 10 ? const Color(0xFFA0FFF8) : paths[i][0] < 6 ? const Color(0xFFFFD898) : Colors.white;
        canvas.drawCircle(pos, 8, Paint()..color = c.withAlpha((fade * 80).round().clamp(0, 255))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5));
        canvas.drawCircle(pos, 3, Paint()..color = c.withAlpha((fade * 160).round().clamp(0, 255)));
      }
    }

    // Stars
    for (int i = 0; i < _stars.length; i++) {
      if (i == 7) continue;
      final pos = _p(i, size);
      final phase = t + (i * 317 % 1200) * 0.005;
      final tw = 0.15 + 0.65 * ((math.sin(phase * 0.8) + 1) / 2);
      final r = _radii[i] * (0.92 + 0.16 * ((math.sin(phase * 0.8) + 1) / 2));
      final c = Color(_colors[i]);
      if (_radii[i] >= 2.0) canvas.drawCircle(pos, r * 2.5, Paint()..color = c.withAlpha((tw * 50).round().clamp(0, 255))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(pos, r, Paint()..color = c.withAlpha((tw * 255).round().clamp(0, 255)));
    }

    // Hub
    final hub = _p(7, size);
    canvas.drawCircle(hub, 20, Paint()..color = const Color(0x09FFFFFF));
    canvas.drawCircle(hub, 11, Paint()..color = const Color(0x0FFFFFFF));
    final co = 0.40 + 0.20 * math.sin(t * 2.1);
    canvas.drawLine(Offset(hub.dx - 42, hub.dy), Offset(hub.dx + 42, hub.dy), Paint()..color = Color.fromRGBO(255, 255, 255, co.clamp(0.0, 1.0))..strokeWidth = 0.6..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(hub.dx, hub.dy - 42), Offset(hub.dx, hub.dy + 42), Paint()..color = Color.fromRGBO(255, 255, 255, co.clamp(0.0, 1.0))..strokeWidth = 0.6..strokeCap = StrokeCap.round);
    for (int i = 0; i < 3; i++) {
      final ph = (time * (i == 2 ? 0.83 : 1.11) + i * 0.33) % 1.0;
      final mr = [55.0, 48.0, 72.0][i]; final r = 5 + (mr - 5) * ph;
      final op = [0.55, 0.35, 0.60][i] * (1.0 - ph); final sw = 1.3 * (1.0 - ph * 0.91);
      canvas.drawCircle(hub, r, Paint()..color = (i == 2 ? Color.fromRGBO(255, 145, 55, op.clamp(0.0, 1.0)) : Color.fromRGBO(255, 255, 255, op.clamp(0.0, 1.0)))..style = PaintingStyle.stroke..strokeWidth = sw);
    }
    final hb = _hb(time);
    canvas.drawCircle(hub, 4.5 * hb, Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(hub, 4.5 * hb, Paint()..color = Colors.white.withAlpha(240)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
    canvas.drawCircle(hub, 4.5 * hb, Paint()..color = Colors.white);
  }

  Offset _p(int i, Size s) => Offset(_stars[i][0] * s.width, _stars[i][1] * s.height);
  void _drawNebula(Canvas c, Size s, double cx, double cy, double r, Color col, double ph) {
    final o = 0.6 + 0.4 * math.sin(ph);
    c.drawOval(Rect.fromCenter(center: Offset(cx * s.width, cy * s.height), width: r * s.width * 2.4, height: r * s.height * 1.9),
      Paint()..shader = RadialGradient(colors: [col.withAlpha((col.alpha * o).round().clamp(0, 255)), Colors.transparent]).createShader(
        Rect.fromCircle(center: Offset(cx * s.width, cy * s.height), radius: r * s.width))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
  }
  double _hb(double t) { final p = (t * 5.26) % 1.0; if (p < 0.08) return 1.0 + 0.08 * (p / 0.08); if (p < 0.18) return 1.08 - 0.07 * ((p - 0.08) / 0.10); if (p < 0.28) return 1.01 + 0.04 * ((p - 0.18) / 0.10); if (p < 0.38) return 1.05 - 0.05 * ((p - 0.28) / 0.10); return 1.0; }

  @override
  bool shouldRepaint(_ConstellationPainter old) => time != old.time;
}

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

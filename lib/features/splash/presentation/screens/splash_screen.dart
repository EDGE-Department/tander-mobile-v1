import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late final AnimationController _heartbeatController;
  late final AnimationController _shimmerController;

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

    // Heartbeat: subtle scale pulsation on the logo.
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    // Shimmer: horizontal highlight sweep on the loading bar.
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
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
    _heartbeatController.dispose();
    _shimmerController.dispose();
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
                      'MADE FOR FILIPINO SENIORS 60+',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'CONNECTING',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLoadingDots(),
                    const SizedBox(height: 12),
                    _buildShimmerBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo at center with three expanding/fading pulse rings behind it.
  Widget _buildPulseRingsWithLogo() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Warm orange halo behind everything.
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x4DFFA050),
                  Color(0x0FFFA050),
                  Colors.transparent,
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Pulse ring 1 (white, no phase offset).
          _PulseRing(
            controller: _pulseController,
            color: Colors.white,
            phaseOffset: 0.0,
          ),
          // Pulse ring 2 (warm orange, offset by half cycle).
          _PulseRing(
            controller: _pulseController,
            color: const Color(0xFFFFC878),
            phaseOffset: 0.5,
          ),
          // Pulse ring 3 (teal, offset by one-third cycle).
          _PulseRing(
            controller: _pulseController,
            color: const Color(0xFF0F9D94),
            phaseOffset: 0.33,
          ),
          // Logo with scale-overshoot entrance + heartbeat.
          AnimatedBuilder(
            animation: Listenable.merge([_logoController, _heartbeatController]),
            builder: (context, child) {
              return Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value * _heartbeatScale(),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.white.withAlpha(60), blurRadius: 24, spreadRadius: 6),
                  BoxShadow(color: const Color(0xFFFFA050).withAlpha(50), blurRadius: 40, spreadRadius: 8),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/icons/tander_icon.png',
                semanticLabel: 'Tander logo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Heartbeat scale factor for a subtle cardiac pulse on the logo.
  double _heartbeatScale() {
    final phase = (_heartbeatController.value * 1.0) % 1.0;
    if (phase < 0.08) return 1.0 + 0.08 * (phase / 0.08);
    if (phase < 0.18) return 1.08 - 0.07 * ((phase - 0.08) / 0.10);
    if (phase < 0.28) return 1.01 + 0.04 * ((phase - 0.18) / 0.10);
    if (phase < 0.38) return 1.05 - 0.05 * ((phase - 0.28) / 0.10);
    return 1.0;
  }

  /// Three animated bouncing dots beneath the connecting label.
  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (_pulseController.value + index * 0.2) % 1.0;
            final scale = 0.7 + 0.6 * ((math.sin(phase * math.pi * 2) + 1) / 2);
            final opacity = 0.3 + 0.7 * ((math.sin(phase * math.pi * 2) + 1) / 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha((opacity * 190).round()),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Horizontal shimmer bar indicating loading progress.
  Widget _buildShimmerBar() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return SizedBox(
          width: 96,
          height: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: Stack(
              children: [
                Container(color: Colors.white.withAlpha(25)),
                Positioned(
                  left: -32 + (_shimmerController.value * 160),
                  child: Container(
                    width: 32,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: Colors.white.withAlpha(115),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            width: 220,
            height: 220,
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
      builder: (_, _) => CustomPaint(painter: _ConstellationPainter(_controller.value), size: Size.infinite),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter(this.time);
  final double time;

  // ── Star data (normalized 0–1 from web 1200×700 viewBox) ──────────

  static const _stars = <List<double>>[
    [0.067, 0.171], [0.150, 0.357], [0.050, 0.571], [0.208, 0.243],
    [0.250, 0.657], [0.350, 0.429], [0.450, 0.486], [0.500, 0.500],
    [0.550, 0.486], [0.650, 0.429], [0.750, 0.243], [0.792, 0.400],
    [0.867, 0.600], [0.917, 0.200], [0.933, 0.714], [0.292, 0.129],
    [0.500, 0.157], [0.708, 0.129], [0.142, 0.136], [0.858, 0.157],
  ];

  static const _baseRadii = <double>[
    2.2, 1.6, 2.8, 1.8, 1.4, 1.8, 2.2, 4.5, 2.2, 1.8,
    1.8, 2.2, 2.8, 1.6, 1.8, 1.4, 1.8, 1.4, 1.8, 1.4,
  ];

  static const _colors = <int>[
    0xD9FFA05A, 0xB3FFFFFF, 0xCCFFB464, 0xA6FFFFFF, 0x80FFFFFF,
    0xA6FFFFFF, 0xBFFFFFFF, 0xFFFFFFFF, 0xBFFFFFFF, 0xA6FFFFFF,
    0xCC96E6E1, 0xD978DCD7, 0xCC64D2CD, 0xA6FFFFFF, 0x80FFFFFF,
    0x80FFFFFF, 0x99FFFFFF, 0x80FFFFFF, 0xA6FFB464, 0xA696E6E1,
  ];

  static const _edges = [
    [0, 1], [1, 2], [2, 4], [0, 3], [3, 5], [4, 5], [5, 6],
    [8, 9], [9, 11], [10, 11], [11, 12], [12, 14], [10, 13],
    [18, 15], [15, 16], [16, 17], [17, 19], [3, 15], [16, 8], [17, 13],
  ];
  static const _bridges = [[6, 7], [7, 8]];

  // ── Responsive helpers ────────────────────────────────────────────

  /// Scale factor relative to a baseline phone width of 393px.
  double _sf(Size s) =>
      (math.min(s.width, s.height) / 393).clamp(0.6, 2.0);

  /// Maps a normalized coordinate to screen position.
  /// On portrait screens, expands Y positions outward from center
  /// so the constellation fills more vertical space.
  Offset _mapNormalized(double nx, double ny, Size s) {
    final aspect = s.width / s.height;
    if (aspect < 1.0) {
      final expansion = 1.0 + (1.0 - aspect) * 0.45;
      final adjustedY = (0.5 + (ny - 0.5) * expansion).clamp(0.02, 0.98);
      return Offset(nx * s.width, adjustedY * s.height);
    }
    return Offset(nx * s.width, ny * s.height);
  }

  /// Maps a constellation star index to its screen position.
  Offset _p(int i, Size s) =>
      _mapNormalized(_stars[i][0], _stars[i][1], s);

  // ── Paint ─────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final sf = _sf(size);
    final t = time * math.pi * 2;

    _paintVignette(canvas, size);
    _paintNebulae(canvas, size, sf, t);
    _paintEdges(canvas, size, sf);
    _paintBridges(canvas, size, sf, t);
    _paintOrbs(canvas, size, sf);
    _paintStars(canvas, size, sf, t);
    _paintHub(canvas, size, sf, t);
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, Colors.black.withAlpha(50)],
          radius: 0.75,
        ).createShader(rect),
    );
  }

  void _paintNebulae(Canvas canvas, Size size, double sf, double t) {
    _drawNebula(canvas, size, sf, 0.17, 0.43, 0.20, const Color(0x20FF8C3C), t * 0.5);
    _drawNebula(canvas, size, sf, 0.82, 0.49, 0.20, const Color(0x1A00C8C0), t * 0.5 + math.pi);
  }

  void _paintEdges(Canvas canvas, Size size, double sf) {
    final paint = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 0.5 * sf;
    for (final e in _edges) {
      canvas.drawLine(_p(e[0], size), _p(e[1], size), paint);
    }
  }

  void _paintBridges(Canvas canvas, Size size, double sf, double t) {
    for (final e in _bridges) {
      final pulse = 0.10 + 0.20 * ((math.sin(t * 1.5) + 1) / 2);
      canvas.drawLine(
        _p(e[0], size),
        _p(e[1], size),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, pulse.clamp(0.0, 1.0))
          ..strokeWidth = 0.8 * sf,
      );
    }
  }

  void _paintOrbs(Canvas canvas, Size size, double sf) {
    const paths = [
      [0, 1],   // left: orange
      [6, 7],   // center-left: white bridge
      [7, 8],   // center-right: white bridge
      [10, 11], // right: teal
    ];
    for (int i = 0; i < paths.length; i++) {
      final from = _p(paths[i][0], size);
      final to = _p(paths[i][1], size);
      final prog = (time + i * 0.125) % 1.0;
      final pos = Offset.lerp(from, to, prog)!;
      final fade = (prog / 0.10).clamp(0.0, 1.0) *
          ((1.0 - prog) / 0.10).clamp(0.0, 1.0);
      if (fade <= 0.02) continue;

      final orbColor = paths[i][0] >= 10
          ? const Color(0xFFA0FFF8)
          : paths[i][0] < 6
              ? const Color(0xFFFFD898)
              : Colors.white;
      canvas.drawCircle(
        pos,
        5 * sf,
        Paint()
          ..color = orbColor.withAlpha((fade * 35).round().clamp(0, 255))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * sf),
      );
      canvas.drawCircle(
        pos,
        2 * sf,
        Paint()..color = orbColor.withAlpha((fade * 90).round().clamp(0, 255)),
      );
    }
  }

  void _paintStars(Canvas canvas, Size size, double sf, double t) {
    for (int i = 0; i < _stars.length; i++) {
      if (i == 7) continue; // Hub drawn separately
      final pos = _p(i, size);
      final groupOffset = (i % 3) * 2.09; // 2π/3 spacing for 3 groups
      final phase = t + groupOffset;
      final twinkle = 0.15 + 0.65 * ((math.sin(phase * 0.5) + 1) / 2);
      final scaledRadius = _baseRadii[i] * sf *
          (0.92 + 0.16 * ((math.sin(phase * 0.5) + 1) / 2));
      final starColor = Color(_colors[i]);

      // Glow layer for larger stars
      if (_baseRadii[i] >= 2.0) {
        canvas.drawCircle(
          pos,
          scaledRadius * 2.0,
          Paint()
            ..color = starColor.withAlpha((twinkle * 30).round().clamp(0, 255))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * sf),
        );
      }
      // Core
      canvas.drawCircle(
        pos,
        scaledRadius,
        Paint()..color = starColor.withAlpha(
          (twinkle * 220).round().clamp(0, 255),
        ),
      );
    }
  }

  void _paintHub(Canvas canvas, Size size, double sf, double t) {
    final hub = _p(7, size);

    // Single expanding ring
    final phase = (time * 1.11) % 1.0;
    final maxRadius = 40.0 * sf;
    final ringRadius = 4 * sf + (maxRadius - 4 * sf) * phase;
    final ringOpacity = 0.50 * (1.0 - phase);
    final strokeWidth = 0.9 * sf * (1.0 - phase * 0.88);
    canvas.drawCircle(
      hub,
      ringRadius,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, ringOpacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Diffraction cross
    final crossOpacity = 0.25 + 0.15 * math.sin(t * 2.1);
    final crossPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, crossOpacity.clamp(0.0, 1.0))
      ..strokeWidth = 0.5 * sf
      ..strokeCap = StrokeCap.round;
    final armLength = 28 * sf;
    canvas.drawLine(
      Offset(hub.dx - armLength, hub.dy),
      Offset(hub.dx + armLength, hub.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(hub.dx, hub.dy - armLength),
      Offset(hub.dx, hub.dy + armLength),
      crossPaint,
    );

    // Heartbeat core
    final heartbeat = _heartbeatScale(time);
    final coreRadius = 3.5 * sf * heartbeat;
    canvas.drawCircle(
      hub,
      coreRadius,
      Paint()
        ..color = Colors.white.withAlpha(200)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * sf),
    );
    canvas.drawCircle(
      hub,
      coreRadius,
      Paint()
        ..color = Colors.white.withAlpha(230)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 * sf),
    );
    canvas.drawCircle(hub, coreRadius, Paint()..color = Colors.white);
  }

  void _drawNebula(
    Canvas canvas,
    Size size,
    double sf,
    double cx,
    double cy,
    double radius,
    Color nebulaColor,
    double phase,
  ) {
    final center = _mapNormalized(cx, cy, size);
    final breathe = 0.6 + 0.4 * math.sin(phase);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * size.width * 2.4,
        height: radius * size.height * 1.9,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [
            nebulaColor.withAlpha(
              (nebulaColor.a * 255 * breathe).round().clamp(0, 255),
            ),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius * size.width),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 * sf),
    );
  }

  double _heartbeatScale(double t) {
    final phase = (t * 5.26) % 1.0;
    if (phase < 0.08) return 1.0 + 0.08 * (phase / 0.08);
    if (phase < 0.18) return 1.08 - 0.07 * ((phase - 0.08) / 0.10);
    if (phase < 0.28) return 1.01 + 0.04 * ((phase - 0.18) / 0.10);
    if (phase < 0.38) return 1.05 - 0.05 * ((phase - 0.28) / 0.10);
    return 1.0;
  }

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

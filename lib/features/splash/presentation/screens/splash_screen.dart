import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/splash/presentation/widgets/splash_painters.dart';

// ── Constants ────────────────────────────────────────────────────────────────

/// Minimum splash display duration matching the web SessionBootstrapProvider.
const Duration _minimumSplashDuration = Duration(seconds: 2);

/// Shimmer bar easing — CSS cubic-bezier(0.445, 0.05, 0.55, 0.95).
const Curve _shimmerCurve = Cubic(0.445, 0.05, 0.55, 0.95);

/// Filipino messages that rotate every 2.8 s on the splash screen.
const List<String> _rotatingMessages = [
  'Kumusta po kayo?',
  'Handa na ang inyong komunidad',
  'Magandang araw sa inyo',
  'Sandali lamang po...',
];

// ── SplashScreen ─────────────────────────────────────────────────────────────

/// Animated splash screen shown during cold-start session bootstrap.
///
/// 1:1 replica of the tander-web AppLoadingScreen (main.tsx).
final class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ─────────────────────────────────────────────────

  late final AnimationController _iconEntranceCtrl;
  late final AnimationController _wordmarkEntranceCtrl;
  late final AnimationController _taglineEntranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _heartbeatCtrl;
  late final AnimationController _haloCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _messageCtrl;
  late final AnimationController _constellationCtrl;
  late final AnimationController _orbACtrl;
  late final AnimationController _orbBCtrl;

  // ── Derived entrance animations ───────────────────────────────────────────

  late final Animation<double> _iconScale;
  late final Animation<double> _iconTranslateY;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconBlur;

  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _wordmarkTranslateY;
  late final Animation<double> _wordmarkBlur;

  late final Animation<double> _taglineOpacity;
  late final Animation<double> _taglineTranslateY;
  late final Animation<double> _taglineBlur;

  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _initEntranceAnimations();
    _startEntranceSequence();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _triggerBootstrap();
    });
  }

  // ── Controller init ───────────────────────────────────────────────────────

  void _initControllers() {
    _iconEntranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _wordmarkEntranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _taglineEntranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _heartbeatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _messageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _orbACtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _orbBCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    // Message controller cycles and advances message index.
    _messageCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _rotatingMessages.length;
        });
        _messageCtrl
          ..reset()
          ..forward();
      }
    });
  }

  // ── Entrance tween sequences ──────────────────────────────────────────────

  void _initEntranceAnimations() {
    const premiumEase = AppCurves.premiumEase;

    // Icon scale: 0% → 0.4, 70% → 1.06, 100% → 1.0
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.06), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _iconEntranceCtrl, curve: premiumEase));

    // Icon translateY: 0% → 30, 70% → -4, 100% → 0
    _iconTranslateY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 30.0, end: -4.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _iconEntranceCtrl, curve: premiumEase));

    // Icon opacity: 0% → 0, 50% → 1, hold
    _iconOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _iconEntranceCtrl, curve: premiumEase));

    // Icon blur: sigma 8 → 0 by 50%
    _iconBlur = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 50),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _iconEntranceCtrl, curve: premiumEase));

    // Wordmark entrance
    _wordmarkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkEntranceCtrl, curve: premiumEase),
    );
    _wordmarkTranslateY = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _wordmarkEntranceCtrl, curve: premiumEase),
    );
    _wordmarkBlur = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _wordmarkEntranceCtrl, curve: premiumEase));

    // Tagline entrance
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineEntranceCtrl, curve: premiumEase),
    );
    _taglineTranslateY = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _taglineEntranceCtrl, curve: premiumEase),
    );
    _taglineBlur = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 60),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _taglineEntranceCtrl, curve: premiumEase));
  }

  // ── Entrance sequence ─────────────────────────────────────────────────────

  void _startEntranceSequence() {
    _iconEntranceCtrl.forward();
    // Wordmark enters 300ms later.
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _wordmarkEntranceCtrl.forward();
    });
    // Tagline enters 500ms later.
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _taglineEntranceCtrl.forward();
    });
    // Heartbeat starts after 1200ms delay.
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _heartbeatCtrl.repeat();
    });
    // Orb B starts after 2500ms delay.
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _orbBCtrl.repeat();
    });
    // Start message rotation.
    _messageCtrl.forward();
  }

  // ── Bootstrap (kept byte-for-byte from previous implementation) ───────────

  void _triggerBootstrap() {
    final minimumTimer = Future<void>.delayed(_minimumSplashDuration);
    final bootstrapFuture = ref
        .read(authNotifierProvider.notifier)
        .bootstrap()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            ref.read(authNotifierProvider.notifier).forceUnauthenticated();
          },
        );
    Future.wait<void>([minimumTimer, bootstrapFuture]);
  }

  @override
  void dispose() {
    _iconEntranceCtrl.dispose();
    _wordmarkEntranceCtrl.dispose();
    _taglineEntranceCtrl.dispose();
    _pulseCtrl.dispose();
    _heartbeatCtrl.dispose();
    _haloCtrl.dispose();
    _shimmerCtrl.dispose();
    _messageCtrl.dispose();
    _constellationCtrl.dispose();
    _orbACtrl.dispose();
    _orbBCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.5),
            end: Alignment(0.7, 0.5),
            colors: [
              Color(0xFFE8734A),
              Color(0xFFCD6038),
              Color(0xFF2A7A74),
              Color(0xFF0F9D94),
            ],
            stops: [0.0, 0.32, 0.62, 1.0],
          ),
        ),
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Ambient orbs
              _buildOrbA(),
              _buildOrbB(),

              // Constellation at 45% opacity
              Positioned.fill(
                child: Opacity(
                  opacity: 0.45,
                  child: AnimatedBuilder(
                    animation: _constellationCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: SplashConstellationPainter(_constellationCtrl.value),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),

              // Film grain
              const Positioned.fill(
                child: Opacity(
                  opacity: 0.035,
                  child: CustomPaint(
                    painter: SplashGrainPainter(),
                    size: Size.infinite,
                  ),
                ),
              ),

              // Vignette
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x59000000),
                      ],
                      radius: 0.65,
                    ),
                  ),
                ),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconGroup(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildWordmarkGroup(screenWidth),
                    const SizedBox(height: 16),
                    _buildRotatingMessage(),
                    const SizedBox(height: 16),
                    _buildConnectingSection(),
                  ],
                ),
              ),

              // Bottom fade
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 128,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0x73120400), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ambient orb A (orange, upper-left) ────────────────────────────────────

  Widget _buildOrbA() {
    return AnimatedBuilder(
      animation: _orbACtrl,
      builder: (_, _) {
        final t = _orbACtrl.value;
        // Keyframes: 0%→(0,0) s1 o0.6, 33%→(45,-25) s1.15 o0.85, 66%→(-30,15) s0.9 o0.7
        double dx, dy, scale, opacity;
        if (t < 0.33) {
          final p = t / 0.33;
          dx = 45.0 * p;
          dy = -25.0 * p;
          scale = 1.0 + 0.15 * p;
          opacity = 0.6 + 0.25 * p;
        } else if (t < 0.66) {
          final p = (t - 0.33) / 0.33;
          dx = 45.0 - 75.0 * p;
          dy = -25.0 + 40.0 * p;
          scale = 1.15 - 0.25 * p;
          opacity = 0.85 - 0.15 * p;
        } else {
          final p = (t - 0.66) / 0.34;
          dx = -30.0 + 30.0 * p;
          dy = 15.0 - 15.0 * p;
          scale = 0.9 + 0.1 * p;
          opacity = 0.7 - 0.1 * p;
        }
        return Positioned(
          left: MediaQuery.sizeOf(context).width * 0.28 - 320 + dx,
          top: MediaQuery.sizeOf(context).height * 0.5 - 320 + dy,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 640,
                height: 640,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x38FF9B37), Colors.transparent],
                    stops: [0.0, 0.65],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Ambient orb B (teal, right) ───────────────────────────────────────────

  Widget _buildOrbB() {
    return AnimatedBuilder(
      animation: _orbBCtrl,
      builder: (_, _) {
        final t = _orbBCtrl.value;
        // Keyframes: 0%→(0,0) s1 o0.5, 50%→(-40,35) s1.1 o0.8
        double dx, dy, scale, opacity;
        if (t < 0.5) {
          final p = t / 0.5;
          dx = -40.0 * p;
          dy = 35.0 * p;
          scale = 1.0 + 0.1 * p;
          opacity = 0.5 + 0.3 * p;
        } else {
          final p = (t - 0.5) / 0.5;
          dx = -40.0 + 40.0 * p;
          dy = 35.0 - 35.0 * p;
          scale = 1.1 - 0.1 * p;
          opacity = 0.8 - 0.3 * p;
        }
        return Positioned(
          right: MediaQuery.sizeOf(context).width * 0.22 - 220 - dx,
          top: MediaQuery.sizeOf(context).height * 0.5 - 220 + dy,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 440,
                height: 440,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2B00D7CD), Colors.transparent],
                    stops: [0.0, 0.65],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Icon group (pulse rings + halo + icon with heartbeat) ─────────────────

  Widget _buildIconGroup() {
    return AnimatedBuilder(
      animation: _iconEntranceCtrl,
      builder: (_, child) {
        final sigma = _iconBlur.value;
        Widget result = Opacity(
          opacity: _iconOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _iconTranslateY.value),
            child: Transform.scale(
              scale: _iconScale.value,
              child: child,
            ),
          ),
        );
        if (sigma > 0.1) {
          result = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
            child: result,
          );
        }
        return result;
      },
      child: SizedBox(
        width: 340,
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Halo glow (breathing)
            AnimatedBuilder(
              animation: _haloCtrl,
              builder: (_, child) => Opacity(
                opacity: 0.7 + 0.3 * _haloCtrl.value,
                child: child,
              ),
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x52FFB950), // rgba(255,185,80,0.32)
                      Color(0x14FF8C32), // rgba(255,140,50,0.08)
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 0.72],
                  ),
                ),
              ),
            ),

            // Pulse ring 1
            SplashPulseRing(
              controller: _pulseCtrl,
              borderWidth: 1.5,
              borderColor: const Color(0x73FFFFFF), // rgba(255,255,255,0.45)
              maxScale: 3.0,
              startOpacity: 0.55,
              phaseOffset: 0.25, // 0.8s / 3.2s
            ),

            // Pulse ring 2
            SplashPulseRing(
              controller: _pulseCtrl,
              borderWidth: 1.0,
              borderColor: const Color(0x59FFC878), // rgba(255,200,120,0.35)
              maxScale: 3.6,
              startOpacity: 0.40,
              phaseOffset: 0.50, // 1.6s / 3.2s
            ),

            // Icon with heartbeat
            AnimatedBuilder(
              animation: _heartbeatCtrl,
              builder: (_, child) {
                final scale = _heartbeatScale(_heartbeatCtrl.value);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 12),
                      blurRadius: 56,
                      color: Color(0x66000000),
                    ),
                    BoxShadow(
                      blurRadius: 90,
                      color: Color(0x66FFA050),
                    ),
                    BoxShadow(
                      spreadRadius: 5,
                      color: Color(0x4DFFFFFF),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/tander_icon.png',
                    width: 104,
                    height: 104,
                    fit: BoxFit.contain,
                    semanticLabel: 'Tander logo',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Heartbeat scale matching web's splash-heartbeat keyframes exactly.
  double _heartbeatScale(double t) {
    final phase = t % 1.0;
    if (phase < 0.10) return 1.0 + 0.08 * (phase / 0.10);
    if (phase < 0.20) return 1.08 - 0.08 * ((phase - 0.10) / 0.10);
    if (phase < 0.30) return 1.0 + 0.05 * ((phase - 0.20) / 0.10);
    if (phase < 0.45) return 1.05 - 0.05 * ((phase - 0.30) / 0.15);
    return 1.0;
  }

  // ── Wordmark + tagline group ──────────────────────────────────────────────

  Widget _buildWordmarkGroup(double screenWidth) {
    final fontSize = (screenWidth * 0.07).clamp(41.6, 60.8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wordmark
        AnimatedBuilder(
          animation: _wordmarkEntranceCtrl,
          builder: (_, child) {
            final sigma = _wordmarkBlur.value;
            Widget result = Opacity(
              opacity: _wordmarkOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _wordmarkTranslateY.value),
                child: child,
              ),
            );
            if (sigma > 0.1) {
              result = ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.decal,
                ),
                child: result,
              );
            }
            return result;
          },
          child: Text(
            'Tander',
            style: AppTypography.brandWordmark(
              fontSize: fontSize,
              color: Colors.white,
              letterSpacing: -0.02 * fontSize,
            ).copyWith(
              shadows: const [
                Shadow(
                  offset: Offset(0, 4),
                  blurRadius: 24,
                  color: Color(0x59000000),
                ),
                Shadow(
                  blurRadius: 70,
                  color: Color(0x4DFFA050),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Tagline
        AnimatedBuilder(
          animation: _taglineEntranceCtrl,
          builder: (_, child) {
            final sigma = _taglineBlur.value;
            Widget result = Opacity(
              opacity: _taglineOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _taglineTranslateY.value),
                child: child,
              ),
            );
            if (sigma > 0.1) {
              result = ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.decal,
                ),
                child: result,
              );
            }
            return result;
          },
          child: const Text(
            'MADE FOR FILIPINO SENIORS 60+',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 3.36,
              color: Color(0xBFFFFFFF), // white 75%
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 8,
                  color: Color(0x38000000),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Rotating message ──────────────────────────────────────────────────────

  Widget _buildRotatingMessage() {
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _messageCtrl,
        builder: (_, _) {
          final t = _messageCtrl.value;
          // Keyframes: 0%,100% → opacity 0, Y 8, blur 4
          //            15%,85% → opacity 1, Y 0, blur 0
          double opacity, translateY, blur;
          if (t < 0.15) {
            final p = t / 0.15;
            opacity = p;
            translateY = 8.0 * (1.0 - p);
            blur = 4.0 * (1.0 - p);
          } else if (t < 0.85) {
            opacity = 1.0;
            translateY = 0.0;
            blur = 0.0;
          } else {
            final p = (t - 0.85) / 0.15;
            opacity = 1.0 - p;
            translateY = 8.0 * p;
            blur = 4.0 * p;
          }

          Widget text = Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, translateY),
              child: Text(
                _rotatingMessages[_messageIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.displayFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xE6FFFFFF), // white 90%
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 12,
                      color: Color(0x40000000),
                    ),
                  ],
                ),
              ),
            ),
          );

          if (blur > 0.1) {
            text = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
                tileMode: TileMode.decal,
              ),
              child: text,
            );
          }
          return text;
        },
      ),
    );
  }

  // ── Connecting section (label + shimmer bar) ──────────────────────────────

  Widget _buildConnectingSection() {
    return AnimatedBuilder(
      animation: _taglineEntranceCtrl,
      builder: (_, child) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _taglineTranslateY.value),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'INIHAHANDA ANG INYONG KWADRA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
              color: Color(0x66FFFFFF), // white 40%
            ),
          ),
          const SizedBox(height: 12),
          _buildShimmerBar(),
        ],
      ),
    );
  }

  // ── Shimmer bar ───────────────────────────────────────────────────────────

  Widget _buildShimmerBar() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, _) {
        final progress = _shimmerCurve.transform(_shimmerCtrl.value);
        // Shimmer is 60% width, travels from -60% to +100% of container.
        final shimmerLeft = -0.6 + progress * 1.6;
        return SizedBox(
          width: 128,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: Stack(
              children: [
                Container(color: const Color(0x1AFFFFFF)), // white 10%
                Positioned(
                  left: shimmerLeft * 128,
                  child: Container(
                    width: 128 * 0.6,
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x80FFFFFF), // white 50%
                          Colors.transparent,
                        ],
                      ),
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
}


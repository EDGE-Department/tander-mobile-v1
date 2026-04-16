import 'dart:math' as math;
import 'dart:ui' show ImageFilter, clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_curves.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../splash/presentation/widgets/splash_painters.dart';
import '../login_background.dart';
import '../login_connection_showcase.dart';
import '../login_desktop_hero.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const LinearGradient _authGradient = LinearGradient(
  begin: Alignment(-1, -1),
  end: Alignment(1, 1),
  colors: [
    Color(0xFFF07040),
    Color(0xFFE86035),
    Color(0xFF2EC878),
    Color(0xFF20BF68),
  ],
  stops: [0.0, 0.30, 0.70, 1.0],
);

const LinearGradient _parchmentGradient = LinearGradient(
  begin: Alignment(-0.15, -1.0),
  end: Alignment(0.15, 1.0),
  colors: [
    Color(0xFFFFFBF8), // warm white
    Color(0xFFFFFAF6), // soft cream
    Color(0xFFFFF9F4), // warm off-white
    Color(0xFFFFF8F2), // light cream
  ],
  stops: [0.0, 0.35, 0.65, 1.0],
);

/// First-time tutorial shown before starting liveness and ID scan.
class LivenessTutorialContent extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback? onBack;

  const LivenessTutorialContent({
    super.key,
    required this.onStart,
    this.onBack,
  });

  @override
  State<LivenessTutorialContent> createState() =>
      _LivenessTutorialContentState();
}

class _LivenessTutorialContentState extends State<LivenessTutorialContent> {
  late final SimulatedOnlineCount _onlineCount;

  @override
  void initState() {
    super.initState();
    _onlineCount = SimulatedOnlineCount();
  }

  @override
  void dispose() {
    _onlineCount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width >= 1024;
    final isTabletPortrait = screenSize.width >= 768 && screenSize.width < 1024;

    if (isLandscape) {
      return _LandscapeLayout(
        onStart: widget.onStart,
        onBack: widget.onBack,
        onlineCount: _onlineCount,
      );
    }

    if (isTabletPortrait) {
      return _TabletPortraitLayout(
        onStart: widget.onStart,
        onBack: widget.onBack,
        onlineCount: _onlineCount,
      );
    }

    return _PhonePortraitLayout(
      onStart: widget.onStart,
      onBack: widget.onBack,
      onlineCount: _onlineCount,
    );
  }
}

// ── Phone Portrait Layout ────────────────────────────────────────────────────

class _PhonePortraitLayout extends StatelessWidget {
  const _PhonePortraitLayout({
    required this.onStart,
    this.onBack,
    required this.onlineCount,
  });

  final VoidCallback onStart;
  final VoidCallback? onBack;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final headerHeight = screenSize.height * 0.30;
    const double sheetOverlap = 32;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen gradient background
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _authGradient),
              ),
            ),
          ),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenSize.height),
              child: Column(
                children: [
                  // Compact header with branding (clean, no scene effects)
                  SizedBox(
                    height: headerHeight,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 20,
                                top: 12,
                              ),
                              child: ValueListenableBuilder<int>(
                                valueListenable: onlineCount,
                                builder: (_, count, __) => OnlineCountBadge(
                                  count: count,
                                  useSeniorsLabel: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: Center(child: _TanderBranding()),
                        ),
                      ],
                    ),
                  ),
                  // White pill-shaped content card with orange accent
                  Transform.translate(
                        offset: const Offset(0, -sheetOverlap),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Orange accent bar at top
                                  Container(
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFF07040),
                                          Color(0xFFE86035),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Content area
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: _parchmentGradient,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                                      child: _ContentBody(onStart: onStart),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(
                        duration: 700.ms,
                        delay: 100.ms,
                        curve: AppCurves.premiumEase,
                      )
                      .slideY(begin: 0.08, curve: AppCurves.premiumEase),
                ],
              ),
            ),
          ),
          // Back button
          if (onBack != null) _BackButton(onBack: onBack!, light: true),
        ],
      ),
    );
  }
}

// ── Tablet Portrait Layout (split panel) ─────────────────────────────────────

class _TabletPortraitLayout extends StatelessWidget {
  const _TabletPortraitLayout({
    required this.onStart,
    this.onBack,
    required this.onlineCount,
  });

  final VoidCallback onStart;
  final VoidCallback? onBack;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leftPanelWidth = screenWidth * 0.42;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left 42% — gradient brand panel
              SizedBox(
                width: leftPanelWidth,
                child: _BrandPanel(onBack: onBack, onlineCount: onlineCount),
              ),
              // Right 58% — parchment form panel
              Expanded(child: _FormPanel(onStart: onStart)),
            ],
          ),
          // Wave seam at boundary
          Positioned(
            left: leftPanelWidth - 64,
            top: 0,
            bottom: 0,
            width: 128,
            child: const IgnorePointer(
              child: CustomPaint(painter: _WaveSeamPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Landscape Layout (split panel) ───────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout({
    required this.onStart,
    this.onBack,
    required this.onlineCount,
  });

  final VoidCallback onStart;
  final VoidCallback? onBack;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 55,
                child: _BrandPanel(onBack: onBack, onlineCount: onlineCount),
              ),
              Expanded(flex: 45, child: _FormPanel(onStart: onStart)),
            ],
          ),
          // Wave seam
          Positioned(
            left: screenWidth * 0.55 - 64,
            top: 0,
            bottom: 0,
            width: 128,
            child: const IgnorePointer(
              child: CustomPaint(painter: _WaveSeamPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Brand Panel (left side for tablet/landscape) ──────────────────────

class _BrandPanel extends StatefulWidget {
  const _BrandPanel({this.onBack, required this.onlineCount});

  final VoidCallback? onBack;
  final SimulatedOnlineCount onlineCount;

  @override
  State<_BrandPanel> createState() => _BrandPanelState();
}

class _BrandPanelState extends State<_BrandPanel>
    with TickerProviderStateMixin {
  late final AnimationController _constellationCtrl;
  late final AnimationController _driftCtrl;

  @override
  void initState() {
    super.initState();
    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _constellationCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.sizeOf(context).width * 0.42;
    final wordmarkSize = (panelWidth * 0.18).clamp(56.0, 88.0);
    final ghostSize = (panelWidth * 0.60).clamp(140.0, 220.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [
            Color(0xFFF07040),
            Color(0xFFE86035),
            Color(0xFF2EC878),
            Color(0xFF20BF68),
          ],
          stops: [0.0, 0.30, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // ── Background Layers ──
          _buildDriftingAurora(panelWidth),

          // Constellation
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child: AnimatedBuilder(
                  animation: _constellationCtrl,
                  builder: (_, _) => CustomPaint(
                    painter: SplashConstellationPainter(
                      _constellationCtrl.value,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Warm center glow
          Positioned.fill(
            child: Center(
              child: Container(
                width: 600,
                height: 600,
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x35FFA050),
                      Color(0x18FF8030),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4, 0.85],
                  ),
                ),
              ),
            ),
          ),

          // Film Grain
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _MobileSceneGrainPainter()),
              ),
            ),
          ),

          _buildVignette(),
          _buildWatermark(ghostSize),

          // ── Scrollable Content ──
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Top Row: Back button + Online count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.onBack != null)
                            _BackIcon(onTap: widget.onBack!)
                          else
                            const SizedBox.shrink(),
                          ValueListenableBuilder<int>(
                            valueListenable: widget.onlineCount,
                            builder: (_, count, __) =>
                                OnlineCountBadge(count: count),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      // Hero Branding
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'MADE FOR FILIPINO SENIORS 60+',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.65),
                              letterSpacing: 3.2,
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 12),
                          LoginLogoWordmarkRow(
                                alignment: MainAxisAlignment.center,
                                wordmarkSize: wordmarkSize,
                                logoSize: wordmarkSize * 0.82,
                              )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 100.ms)
                              .slideY(begin: 0.1),
                          const SizedBox(height: 24),
                          Text(
                                'Connect with fellow seniors\nwho understand your world',
                                textAlign: TextAlign.center,
                                style: AppTypography.h2.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  height: 1.3,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x2E000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 300.ms)
                              .moveY(begin: 10),
                          const SizedBox(height: 16),
                          const SizedBox(
                            width: 320,
                            child: LoginFilipinoValuesMarquee(),
                          ).animate().fadeIn(duration: 800.ms, delay: 500.ms),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Connection Showcase Card
                      Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x2E0C0400),
                                      blurRadius: 56,
                                      offset: Offset(0, 22),
                                    ),
                                  ],
                                ),
                                child: const ConnectionShowcase(),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 700.ms, delay: 700.ms)
                          .scale(begin: const Offset(0.98, 0.95)),
                    ]),
                  ),
                ),

                // Spacer to push footer to bottom
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _HeroBadge(
                              icon: Icons.people,
                              label: '2,400+ members',
                            ),
                            _HeroBadge(
                              icon: Icons.verified_user,
                              label: 'ID-verified',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '\u00A9 2026 Tander. All rights reserved.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriftingAurora(double panelWidth) {
    return AnimatedBuilder(
      animation: _driftCtrl,
      builder: (context, _) {
        final t = _driftCtrl.value * math.pi * 2;
        return Stack(
          children: [
            Positioned(
              top: -60 + math.sin(t) * 30,
              left: -40 + math.cos(t * 0.8) * 40,
              width: panelWidth * 0.85,
              height: 400,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x52FF9656), Colors.transparent],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100 + math.cos(t * 0.6) * 40,
              right: -80 + math.sin(t * 0.9) * 50,
              width: panelWidth * 0.75,
              height: 450,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x3D60D6BC), Colors.transparent],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVignette() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 240,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF120400).withValues(alpha: 0.42),
                const Color(0xFF0A0200).withValues(alpha: 0.12),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatermark(double ghostSize) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              'Tander',
              style: AppTypography.brandWordmark(
                fontSize: ghostSize,
                color: Colors.white.withValues(alpha: 0.07),
                letterSpacing: -0.02 * ghostSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackIcon extends StatelessWidget {
  const _BackIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: const Icon(
          PhosphorIconsBold.arrowLeft,
          color: Colors.white,
          size: 22,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Shared Form Panel (right side for tablet/landscape) ──────────────────────

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _parchmentGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _ParchmentDecor())),
          SafeArea(
            left: false,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _TutorialCard(onStart: onStart)
                      .animate()
                      .fadeIn(
                        duration: 650.ms,
                        delay: 120.ms,
                        curve: AppCurves.premiumEase,
                      )
                      .slideX(begin: 0.04, curve: AppCurves.premiumEase),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tutorial Card (mimics LoginFormCard) ────────────────────────────────────

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(32);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: borderRadius,
        border: Border.all(color: const Color(0x33FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 80,
            offset: Offset(0, 48),
            spreadRadius: -16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top accent bar
            Container(
              height: 8,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE67E22),
                    Color(0xFFF39C12),
                    Color(0xFFE67E22),
                  ],
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x4DE67E22), blurRadius: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _ContentBody(onStart: onStart),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Content Body (shared across all layouts) ─────────────────────────────────

class _ContentBody extends StatelessWidget {
  const _ContentBody({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ready to verify',
          textAlign: TextAlign.center,
          style: AppTypography.displayLg.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 400.ms).moveY(begin: 12),
        const SizedBox(height: 14),
        Text(
          'Grab your physical ID and make sure\nyou are in a well-lit space.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 550.ms).moveY(begin: 8),
        const SizedBox(height: 36),

        // Hint cards
        _HintCard(
          icon: PhosphorIconsDuotone.camera,
          color: const Color(0xFFFF8266),
          text: 'Look at the camera — we\'ll capture automatically',
          delay: 700.ms,
        ),
        const SizedBox(height: 14),
        _HintCard(
          icon: PhosphorIconsDuotone.creditCard,
          color: const Color(0xFF5BBFB3),
          text: 'Place your ID in the frame — we\'ll read it for you',
          delay: 850.ms,
        ),
        const SizedBox(height: 14),
        _HintCard(
          icon: PhosphorIconsDuotone.lock,
          color: const Color(0xFF5BBFB3),
          text: 'Your info stays private and encrypted',
          delay: 1000.ms,
        ),

        const SizedBox(height: 48),
        _StartButton(onStart: onStart),
        const SizedBox(height: 24),

        // Trust badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsFill.shieldCheck,
              size: 16,
              color: AppColors.secondary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'SECURE & ENCRYPTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 800.ms, delay: 1400.ms),
      ],
    );
  }
}

// ── Hint Card ────────────────────────────────────────────────────────────────

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.color,
    required this.text,
    required this.delay,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        text,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 15,
                          color: AppColors.textStrong,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay)
        .moveX(begin: 16, curve: AppCurves.premiumEase);
  }
}

// ── Start Button ─────────────────────────────────────────────────────────────

class _StartButton extends StatefulWidget {
  const _StartButton({required this.onStart});
  final VoidCallback onStart;

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFFE67E22), Color(0xFFD35400)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE67E22).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onStart();
              },
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shimmer
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment(
                            -1.5 + (_shimmerCtrl.value * 3),
                            0,
                          ),
                          widthFactor: 0.3,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'START VERIFICATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        PhosphorIconsBold.arrowRight,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 1200.ms)
        .moveY(begin: 20, curve: AppCurves.premiumEase);
  }
}

// ── Back Button ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack, this.light = false});

  final VoidCallback onBack;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onBack();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: light
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: light
                    ? Colors.white.withValues(alpha: 0.16)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              PhosphorIconsBold.arrowLeft,
              color: light ? Colors.white : AppColors.textStrong,
              size: 20,
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
      ),
    );
  }
}

// ── Tander Branding ─────────────────────────────────────────────────────────

class _TanderBranding extends StatelessWidget {
  const _TanderBranding();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wordmarkSize = (screenWidth * 0.14).clamp(48.0, 72.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MADE FOR FILIPINO SENIORS 60+',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.28 * 9,
            color: Colors.white.withValues(alpha: 0.60),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60D6BC).withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/tander_icon.png',
              width: 88,
              height: 88,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tander',
          style:
              AppTypography.brandWordmark(
                fontSize: wordmarkSize,
                color: Colors.white,
                letterSpacing: -0.03 * wordmarkSize,
              ).copyWith(
                height: 0.95,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 4),
                    blurRadius: 24,
                    color: Color(0x38000000),
                  ),
                  Shadow(blurRadius: 50, color: Color(0x47FFA050)),
                ],
              ),
        ),
      ],
    );
  }
}

// ── Header Scene (phone portrait) ────────────────────────────────────────────

class _HeaderScene extends StatefulWidget {
  const _HeaderScene();

  @override
  State<_HeaderScene> createState() => _HeaderSceneState();
}

class _HeaderSceneState extends State<_HeaderScene>
    with TickerProviderStateMixin {
  late final AnimationController _constellationCtrl;
  late final AnimationController _driftCtrl;

  @override
  void initState() {
    super.initState();
    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _constellationCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _driftCtrl,
          builder: (context, child) {
            final driftX = math.sin(_driftCtrl.value * math.pi * 2) * 15;
            final driftY = math.cos(_driftCtrl.value * math.pi * 2) * 10;

            return Stack(
              fit: StackFit.expand,
              children: [
                // Orange aurora blob with drift
                Positioned(
                  top: -h * 0.18 + driftY,
                  left: -w * 0.10 + driftX,
                  child: Container(
                    width: w * 0.65,
                    height: h * 0.80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x52FF9656),
                          Color(0x1FDC6937),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.48, 0.74],
                      ),
                    ),
                  ),
                ),
                // Teal aurora blob with drift
                Positioned(
                  bottom: -h * 0.05 - driftY,
                  right: -w * 0.10 - driftX,
                  child: Container(
                    width: w * 0.50,
                    height: h * 0.65,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x3D60D6BC),
                          Color(0x0F1C927A),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.45, 0.75],
                      ),
                    ),
                  ),
                ),

                // Add subtle floating social orbs for life
                ...List.generate(3, (i) {
                  final seed = i * 133;
                  final tx =
                      math.sin((_driftCtrl.value + seed) * math.pi * 2) * 20;
                  final ty =
                      math.cos((_driftCtrl.value + seed * 0.7) * math.pi * 2) *
                      15;
                  final basePos = [
                    Offset(w * 0.2, h * 0.3),
                    Offset(w * 0.8, h * 0.25),
                    Offset(w * 0.7, h * 0.7),
                  ];
                  return Positioned(
                    left: basePos[i].dx + tx,
                    top: basePos[i].dy + ty,
                    child: Container(
                      width: 40 + (i * 10),
                      height: 40 + (i * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: 0.03 + (i * 0.01),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  );
                }),

                // Grain
                const Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPaint(painter: _MobileSceneGrainPainter()),
                  ),
                ),
                // Constellation
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.45,
                      child: AnimatedBuilder(
                        animation: _constellationCtrl,
                        builder: (_, _) => CustomPaint(
                          painter: SplashConstellationPainter(
                            _constellationCtrl.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // "60+" watermark
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fontSize = clampDouble(
                            constraints.maxWidth * 0.34,
                            116,
                            176,
                          );
                          return Transform.translate(
                            offset: Offset(0, fontSize * 0.08),
                            child: Text(
                              '60+',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                fontWeight: FontWeight.w900,
                                fontSize: fontSize,
                                color: Colors.white.withValues(alpha: 0.05),
                                height: 1,
                                letterSpacing: -0.05 * fontSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Bottom vignette
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.40,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0x6B120400),
                          Color(0x1F0A0200),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Parchment Decor (right panel background details) ─────────────────────────

class _ParchmentDecor extends StatelessWidget {
  const _ParchmentDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: Opacity(
            opacity: 0.45,
            child: CustomPaint(painter: _ParchmentDotGridPainter(spacing: 24)),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x1AE67E22),
                    Color(0x0AE67E22),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 0.85],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 80,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x0FE67E22), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sheet Handle ─────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

// ── Mobile Parchment Sheet ──────────────────────────────────────────────────

class _MobileParchmentSheet extends StatelessWidget {
  const _MobileParchmentSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.06),
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const _SheetHandle(),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Painters ─────────────────────────────────────────────────────────────────

class _MobileSceneGrainPainter extends CustomPainter {
  const _MobileSceneGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int index = 0; index < 520; index++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.2 + random.nextDouble() * 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ParchmentDotGridPainter extends CustomPainter {
  const _ParchmentDotGridPainter({this.spacing = 26});

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14B46414)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParchmentDotGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing;
  }
}

class _WaveSeamPainter extends CustomPainter {
  const _WaveSeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.53, 0)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.078,
        size.width * 0.80,
        size.height * 0.143,
        size.width * 0.59,
        size.height * 0.266,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.39,
        size.width * 0.72,
        size.height * 0.456,
        size.width * 0.56,
        size.height * 0.576,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.696,
        size.width * 0.67,
        size.height * 0.75,
        size.width * 0.53,
        size.height * 0.876,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.96,
        size.width * 0.56,
        size.height * 0.983,
        size.width * 0.53,
        size.height,
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x38E6A03C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

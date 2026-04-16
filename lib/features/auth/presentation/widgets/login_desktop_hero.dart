import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_connection_showcase.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_constellation.dart';

/// Desktop/landscape left panel for the login screen.
///
/// Matches the web's `lg:flex lg:w-[60%]` hero panel with:
/// - Auth gradient background (#F07040 -> #E86035 -> #2EC878 -> #20BF68)
/// - VividAurora blobs + constellation + social orbs
/// - "60+" watermark, "MADE FOR FILIPINO SENIORS 60+" label
/// - Large "Tander" wordmark
/// - Filipino values marquee
/// - Connection showcase card + testimonials
/// - Trust badges: "2,400+ members", "ID-verified"
/// - Copyright notice
class DesktopHeroPanel extends StatelessWidget {
  const DesktopHeroPanel({required this.onlineCount, super.key});

  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
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
          _buildAuroraBlobs(),
          LoginConstellation(),
          // Warm center glow — matches web's ambient golden light
          Positioned.fill(
            child: Center(
              child: Container(
                width: 700,
                height: 550,
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x35FFA050), // warm golden center
                      Color(0x18FF8030), // fade
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4, 0.85],
                  ),
                ),
              ),
            ),
          ),
          _buildVignette(),
          _buildWatermark(context),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(child: _buildHeroContent(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  const SliverToBoxAdapter(child: LoginFilipinoValuesMarquee()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: const ConnectionShowcase(),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [_buildFooter()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuroraBlobs() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Warm orange blob top-left
            Positioned(
              top: -20,
              left: -20,
              width: 300,
              height: 260,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(130),
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x70FF8C46),
                      Color(0x38F06432),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 0.70],
                  ),
                ),
              ),
            ),
            // Teal blob bottom-right
            Positioned(
              bottom: -20,
              right: -30,
              width: 280,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(120),
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x472EC88C),
                      Color(0x240FA094),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.45, 0.70],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVignette() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 300,
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

  Widget _buildWatermark(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.6;
    final fontSize = (width * 0.36).clamp(200.0, 420.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Transform.translate(
            offset: Offset(0, fontSize * 0.06),
            child: Text(
              '60+',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: fontSize,
                color: Colors.white.withValues(alpha: 0.042),
                height: 1,
                letterSpacing: -0.04 * fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Spacer(),
        ValueListenableBuilder<int>(
          valueListenable: onlineCount,
          builder: (_, count, _) => OnlineCountBadge(count: count),
        ),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // "MADE FOR FILIPINO SENIORS 60+"
            Text(
              'MADE FOR FILIPINO SENIORS 60+',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.65),
                letterSpacing: 3.2,
              ),
            ),
            const SizedBox(height: 12),

            // Logo circle + "Tander" wordmark row (matching web)
            const LoginLogoWordmarkRow(),
            const SizedBox(height: 24),

            // Tagline
            Text(
              'Connect with fellow seniors\nwho understand your world',
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontSize: 22,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Trust badges — centered, matching web
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _TrustBadge(icon: Icons.people, label: '2,400+ members'),
            _TrustBadge(icon: Icons.verified_user, label: 'ID-verified'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '\u00A9 2026 Tander. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
      ],
    );
  }
}

// ── Filipino Values Marquee ─────────────────────────────────────────

const _marqueeText =
    'PAGMAMAHAL \u00B7 TIWALA \u00B7 SAMA-SAMA \u00B7 TAHANAN '
    '\u00B7 KWENTUHAN \u00B7 MALASAKIT';

class TabletPortraitHeroPanel extends StatelessWidget {
  const TabletPortraitHeroPanel({required this.onlineCount, super.key});

  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    const heroHeight = 320.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(42),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29180804),
            blurRadius: 72,
            offset: Offset(0, 28),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(42),
        child: SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              const Positioned.fill(
                child: LoginHeaderBackground(
                  headerHeight: heroHeight,
                  showSocialOrbs: false,
                ),
              ),
              LoginConstellation(),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    '60+',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 240,
                      color: Colors.white.withValues(alpha: 0.04),
                      height: 1,
                      letterSpacing: -12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        ValueListenableBuilder<int>(
                          valueListenable: onlineCount,
                          builder: (_, count, _) =>
                              OnlineCountBadge(count: count),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 390),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MADE FOR FILIPINO SENIORS 60+',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      letterSpacing: 3.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const LoginLogoWordmarkRow(
                                    alignment: MainAxisAlignment.start,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Connect with fellow seniors who understand your world.',
                                    style: AppTypography.h2.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.88,
                                      ),
                                      height: 1.24,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0x2E000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const SizedBox(
                                    width: 332,
                                    child: LoginFilipinoValuesMarquee(),
                                  ),
                                  const SizedBox(height: 16),
                                  const Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _TrustBadge(
                                        icon: Icons.people,
                                        label: '2,400+ members',
                                      ),
                                      _TrustBadge(
                                        icon: Icons.verified_user,
                                        label: 'ID-verified',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 296,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x2E0C0400),
                                        blurRadius: 56,
                                        offset: Offset(0, 22),
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(
                                    width: 296,
                                    child: ConnectionShowcase(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

class LoginFilipinoValuesMarquee extends StatefulWidget {
  const LoginFilipinoValuesMarquee();

  @override
  State<LoginFilipinoValuesMarquee> createState() => _LoginFilipinoValuesMarqueeState();
}

class _LoginFilipinoValuesMarqueeState extends State<LoginFilipinoValuesMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (_, _) => _MarqueeContent(progress: _scrollController.value),
        ),
      ),
    );
  }
}

class _MarqueeContent extends StatelessWidget {
  const _MarqueeContent({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.28 * 9,
      color: Colors.white.withValues(alpha: 0.20),
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        // Use a large fixed width for the text so we can scroll across it
        const textWidth = 1200.0;
        final offset = -progress * textWidth;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: SizedBox(
            width: textWidth * 2,
            child: Text(
              '$_marqueeText     $_marqueeText     $_marqueeText     ',
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ),
        );
      },
    );
  }
}

// ── Trust Badge ─────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo + wordmark row ──────────────────────────────────────────────

/// Tander app icon (already has white circle baked in) + "Tander"
/// cursive wordmark, matching the web hero panel layout.
///
/// [logoSize] and [wordmarkSize] are optional overrides. When null,
/// sizes are derived from the panel width (desktop default behaviour).
class LoginLogoWordmarkRow extends StatelessWidget {
  const LoginLogoWordmarkRow({
    this.alignment = MainAxisAlignment.center,
    this.logoSize,
    this.wordmarkSize,
  });

  final MainAxisAlignment alignment;
  final double? logoSize;
  final double? wordmarkSize;

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.sizeOf(context).width * 0.6;
    final effectiveWordmarkSize =
        wordmarkSize ?? (panelWidth * 0.14).clamp(68.0, 118.0);
    final effectiveLogoSize = logoSize ?? effectiveWordmarkSize * 0.78;

    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App icon — already a white circle with hearts
        Image.asset(
          'assets/icons/tander_icon.png',
          width: effectiveLogoSize,
          height: effectiveLogoSize,
          fit: BoxFit.contain,
          semanticLabel: 'Tander logo',
        ),
        SizedBox(width: effectiveWordmarkSize * 0.06),
        LoginWordmarkGlowSweep(wordmarkSize: effectiveWordmarkSize),
      ],
    );
  }
}

// ── Wordmark glow sweep ─────────────────────────────────────────────

/// One-time 3s glow sweep across the "Tander" wordmark,
/// starting after a 1.6s delay. Matches the web's shimmer effect.
///
/// [wordmarkSize] overrides the default panel-width-based calculation.
class LoginWordmarkGlowSweep extends StatefulWidget {
  const LoginWordmarkGlowSweep({this.wordmarkSize});

  final double? wordmarkSize;

  @override
  State<LoginWordmarkGlowSweep> createState() => _LoginWordmarkGlowSweepState();
}

class _LoginWordmarkGlowSweepState extends State<LoginWordmarkGlowSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  static const Duration _sweepDelay = Duration(milliseconds: 1600);
  static const Duration _sweepDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: _sweepDuration,
    );
    // Start the sweep after the delay — runs exactly once
    Future<void>.delayed(_sweepDelay, () {
      if (mounted) _sweepController.forward();
    });
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use explicit size when provided (e.g. tablet portrait).
    // Desktop falls back to panel-width-based calculation.
    final panelWidth = MediaQuery.sizeOf(context).width * 0.6;
    final wordmarkSize =
        widget.wordmarkSize ?? (panelWidth * 0.14).clamp(68.0, 118.0);

    final wordmarkStyle =
        AppTypography.brandWordmark(
          fontSize: wordmarkSize,
          color: Colors.white,
          letterSpacing: -0.03 * wordmarkSize,
        ).copyWith(
          height: 0.95,
          shadows: const [
            Shadow(
              color: Color(0x40000000),
              blurRadius: 40,
              offset: Offset(0, 6),
            ),
            Shadow(color: Color(0x77FFA050), blurRadius: 110),
            Shadow(color: Color(0x40FF8030), blurRadius: 140),
            Shadow(color: Color(0x20FFB060), blurRadius: 180),
          ],
        );

    return AnimatedBuilder(
      animation: _sweepController,
      builder: (_, child) {
        if (!_sweepController.isAnimating && _sweepController.value == 0) {
          // Before sweep starts — render plain text
          return child!;
        }

        // Sweep position: -0.3 to 1.3 so the glow band enters and exits
        final sweepCenter = -0.3 + _sweepController.value * 1.6;

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Colors.white,
              Color(0xFFFFE0B0), // warm glow peak
              Colors.white,
            ],
            stops: [
              (sweepCenter - 0.15).clamp(0.0, 1.0),
              sweepCenter.clamp(0.0, 1.0),
              (sweepCenter + 0.15).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          blendMode: BlendMode.modulate,
          child: child!,
        );
      },
      child: Text('Tander', style: wordmarkStyle),
    );
  }
}

// ── Tablet Portrait Branding Block ──────────────────────────────────

/// Centered branding block for the tablet portrait login layout.
///
/// Renders: label → logo+wordmark row → tagline → Filipino values marquee.
/// Used exclusively by `_TabletPortraitLayout` in `login_screen.dart`.
class TabletBrandingBlock extends StatelessWidget {
  const TabletBrandingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wordmarkSize = (screenWidth * 0.085).clamp(68.0, 96.0);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        children: [
          Text(
            'MADE FOR FILIPINO SENIORS 60+',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 3.2,
            ),
          ),
          const SizedBox(height: 12),
          LoginLogoWordmarkRow(
            alignment: MainAxisAlignment.center,
            logoSize: 72.0,
            wordmarkSize: wordmarkSize,
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              'Connect with fellow seniors who understand your world',
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.24,
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
                .fadeIn(duration: 500.ms, delay: 500.ms)
                .slideY(begin: 0.06),
          ),
          const SizedBox(height: 10),
          const SizedBox(
            width: 420,
            child: LoginFilipinoValuesMarquee(),
          ),
        ],
      ),
    );
  }
}

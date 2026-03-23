import 'package:flutter/material.dart';

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
          const LoginConstellation(),
          _buildVignette(),
          _buildWatermark(context),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 24,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  SliverToBoxAdapter(child: _buildHeroContent(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  const SliverToBoxAdapter(child: _FilipinoValuesMarquee()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: const ConnectionShowcase(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
        Image.asset(
          'assets/icons/tander_logo.png',
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 10),
        Text(
          'Tander',
          style: AppTypography.h2.copyWith(
            fontSize: 24,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        ValueListenableBuilder<int>(
          valueListenable: onlineCount,
          builder: (_, count, _) => OnlineCountBadge(count: count),
        ),
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "MADE FOR FILIPINO SENIORS 60+"
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

        // Large "Tander" wordmark
        Text(
          'Tander',
          style: AppTypography.displayXl.copyWith(
            fontSize: 80,
            color: Colors.white,
            letterSpacing: -2.4,
            height: 0.95,
            shadows: const [
              Shadow(
                color: Color(0x40000000),
                blurRadius: 40,
                offset: Offset(0, 6),
              ),
              Shadow(
                color: Color(0x47FFA050),
                blurRadius: 80,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tagline
        Text(
          'Connect with fellow seniors\nwho understand your world',
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
    );
  }

  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trust badges
        const Wrap(
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

class _FilipinoValuesMarquee extends StatefulWidget {
  const _FilipinoValuesMarquee();

  @override
  State<_FilipinoValuesMarquee> createState() => _FilipinoValuesMarqueeState();
}

class _FilipinoValuesMarqueeState extends State<_FilipinoValuesMarquee>
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
          builder: (_, _) => _MarqueeContent(
            progress: _scrollController.value,
          ),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
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

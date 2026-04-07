import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/forgot_password_components.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';

// ── Form card shell ──────────────────────────────────────────────────

/// White card with rounded corners, accent bar (desktop) or drag handle
/// (mobile). Switches between [formContent] and [successContent].
class ForgotPasswordFormCard extends StatelessWidget {
  const ForgotPasswordFormCard({
    required this.isWide,
    required this.isCodeSent,
    required this.formContent,
    required this.successContent,
    super.key,
  });

  final bool isWide;
  final bool isCodeSent;
  final Widget formContent;
  final Widget successContent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFCF8)],
        ),
        borderRadius: BorderRadius.circular(isWide ? 32 : 28),
        border: Border.all(color: const Color(0x1AE6A032)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0FB46414),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x1AC85A12),
            blurRadius: 48,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 80,
            offset: Offset(0, 32),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWide ? 32 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAccentBar(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 40 : 32,
                isWide ? 36 : 32,
                isWide ? 40 : 32,
                isWide ? 32 : 32,
              ),
              child: isCodeSent ? successContent : formContent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccentBar() {
    return Container(
      height: 2.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
        ),
      ),
    );
  }
}

// ── Security note ────────────────────────────────────────────────────

/// Shield icon + "We'll send a secure 6-digit code - no spam, ever".
class SecurityNote extends StatelessWidget {
  const SecurityNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 13, color: AppColors.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            "We'll send a secure 6-digit code \u2014 no spam, ever",
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Remember password footer ─────────────────────────────────────────

/// Heart circle + "Remember your password? Sign in instead" link.
class RememberPasswordFooter extends StatelessWidget {
  const RememberPasswordFooter({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.favorite, size: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: onSignIn,
              child: Text.rich(
                TextSpan(
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  children: const [
                    TextSpan(text: 'Remember your password? '),
                    TextSpan(
                      text: 'Sign in instead',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success icon orb ─────────────────────────────────────────────────

/// Green checkmark orb shown after the reset code is sent successfully.
class SuccessIconOrb extends StatelessWidget {
  const SuccessIconOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFF2E8B57), Color(0xFF38A169)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x732E8B57),
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.check_circle, size: 46, color: Colors.white),
      ),
    );
  }
}

// ── Mobile header ────────────────────────────────────────────────────

/// Gradient header for the phone layout, matching the web's mobile header
/// for the forgot-password page: "Account Recovery" + tagline + badge.
class ForgotPasswordMobileHeader extends StatelessWidget {
  const ForgotPasswordMobileHeader({
    required this.headerHeight,
    required this.onlineCount,
    super.key,
  });

  final double headerHeight;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final horizontalOverscan = MediaQuery.sizeOf(context).width * 0.10;

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -horizontalOverscan,
            right: -horizontalOverscan,
            top: 0,
            bottom: 0,
            child: const IgnorePointer(child: _ForgotMobileHeaderScene()),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLogoRow(),
                    const SizedBox(height: 6),
                    _buildHeading(),
                    const SizedBox(height: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: onlineCount,
                      builder: (_, count, _) =>
                          OnlineCountBadge(count: count, useSeniorsLabel: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/tander_icon.png',
          width: 32,
          height: 32,
          semanticLabel: 'Tander logo',
        ),
        const SizedBox(width: 8),
        Text(
          'Tander',
          style: AppTypography.brandWordmark(
            fontSize: 21,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Text(
      'Forgot Password',
      style: AppTypography.h1.copyWith(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ForgotMobileHeaderScene extends StatelessWidget {
  const _ForgotMobileHeaderScene();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _ForgotSceneGrainPainter()),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Opacity(
                  opacity: 0.9,
                  child: CustomPaint(painter: _ForgotConstellationPainter()),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fontSize = (constraints.maxWidth * 0.34).clamp(
                    116.0,
                    176.0,
                  );
                  return Center(
                    child: Transform.translate(
                      offset: Offset(0, fontSize * 0.08),
                      child: Text(
                        '60+',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: fontSize,
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          letterSpacing: -0.05 * fontSize,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotConstellationNode {
  const _ForgotConstellationNode(this.x, this.y, this.radius, this.color);

  final double x;
  final double y;
  final double radius;
  final Color color;
}

class _ForgotConstellationPainter extends CustomPainter {
  const _ForgotConstellationPainter();

  static const List<_ForgotConstellationNode> _nodes = [
    _ForgotConstellationNode(0.12, 0.34, 2.2, Color(0xE6FFA05A)),
    _ForgotConstellationNode(0.25, 0.24, 1.7, Color(0xBFFFFFFF)),
    _ForgotConstellationNode(0.23, 0.58, 1.6, Color(0x8CFFFFFF)),
    _ForgotConstellationNode(0.39, 0.46, 2.1, Color(0xCCFFFFFF)),
    _ForgotConstellationNode(0.50, 0.50, 4.4, Color(0xFFFFFFFF)),
    _ForgotConstellationNode(0.61, 0.45, 2.1, Color(0xCCFFFFFF)),
    _ForgotConstellationNode(0.76, 0.24, 1.7, Color(0xD996E6DF)),
    _ForgotConstellationNode(0.85, 0.42, 2.3, Color(0xE678DCD7)),
    _ForgotConstellationNode(0.78, 0.62, 1.8, Color(0x8CFFFFFF)),
    _ForgotConstellationNode(0.50, 0.16, 1.7, Color(0xA6FFFFFF)),
    _ForgotConstellationNode(0.05, 0.20, 1.4, Color(0xB3FFB464)),
    _ForgotConstellationNode(0.95, 0.18, 1.4, Color(0xB396E6DF)),
  ];

  static const List<List<int>> _normalEdges = [
    [0, 1],
    [0, 3],
    [2, 3],
    [5, 6],
    [5, 7],
    [7, 8],
    [9, 4],
    [10, 0],
    [11, 6],
  ];

  static const List<List<int>> _bridgeEdges = [
    [3, 4],
    [4, 5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    final bridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..strokeWidth = 1.05
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    for (final edge in _normalEdges) {
      final from = _resolve(size, _nodes[edge[0]]);
      final to = _resolve(size, _nodes[edge[1]]);
      canvas.drawLine(from, to, linePaint);
    }

    for (final edge in _bridgeEdges) {
      final from = _resolve(size, _nodes[edge[0]]);
      final to = _resolve(size, _nodes[edge[1]]);
      canvas.drawLine(from, to, bridgePaint);
    }

    final hubGlowPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final hubCenter = _resolve(size, _nodes[4]);
    canvas.drawCircle(hubCenter, 18, hubGlowPaint);

    for (final node in _nodes) {
      final offset = _resolve(size, node);
      final glowPaint = Paint()
        ..color = node.color.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          node.radius >= 4 ? 8 : 3,
        );
      final fillPaint = Paint()..color = node.color;
      canvas.drawCircle(offset, node.radius * 2.2, glowPaint);
      canvas.drawCircle(offset, node.radius, fillPaint);
    }
  }

  static Offset _resolve(Size size, _ForgotConstellationNode node) {
    const horizontalScale = 1.08;
    const verticalScale = 0.90;
    const horizontalInset = 0.08;
    const verticalInset = 0.10;

    final resolvedX = (0.5 + (node.x - 0.5) * horizontalScale).clamp(
      horizontalInset,
      1 - horizontalInset,
    );
    final resolvedY = (0.5 + (node.y - 0.5) * verticalScale).clamp(
      verticalInset,
      1 - verticalInset,
    );

    return Offset(size.width * resolvedX, size.height * resolvedY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ForgotSceneGrainPainter extends CustomPainter {
  const _ForgotSceneGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (int index = 0; index < 320; index++) {
      final x = (index * 37 % 997) / 997 * size.width;
      final y = (index * 91 % 673) / 673 * size.height;
      final radius = 0.2 + ((index * 13 % 10) / 10) * 0.6;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

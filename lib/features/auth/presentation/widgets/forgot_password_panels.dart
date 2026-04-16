import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/forgot_password_components.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/splash/presentation/widgets/splash_painters.dart';

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

class _ForgotMobileHeaderScene extends StatefulWidget {
  const _ForgotMobileHeaderScene();

  @override
  State<_ForgotMobileHeaderScene> createState() =>
      _ForgotMobileHeaderSceneState();
}

class _ForgotMobileHeaderSceneState extends State<_ForgotMobileHeaderScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
          // Web's 19-node animated constellation at 45% opacity
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => CustomPaint(
                    painter: SplashConstellationPainter(_ctrl.value),
                  ),
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

import 'package:flutter/foundation.dart';
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
    final borderRadius = BorderRadius.circular(32);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Orange accent bar at top (matching login)
          _buildAccentBar(),
          // White card content
          Container(
            decoration: const BoxDecoration(color: Color(0xFFFFFBF8)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 24,
                vertical: 32,
              ),
              child: isCodeSent ? successContent : formContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentBar() {
    return Container(
      height: 6,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF07040), Color(0xFFE86035)],
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

/// Simple gradient header for the phone layout (matching login screen).
class ForgotPasswordMobileHeader extends StatelessWidget {
  const ForgotPasswordMobileHeader({
    required this.headerHeight,
    required this.onlineCount,
    super.key,
  });

  final double headerHeight;
  final ValueListenable<int> onlineCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ghostFontSize = (screenWidth * 0.24).clamp(72.0, 96.0);
    final wordmarkSize = (screenWidth * 0.14).clamp(48.0, 60.0);

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ghost wordmark background
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -ghostFontSize * 0.08),
                  child: Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: ghostFontSize,
                      color: Colors.white.withValues(alpha: 0.09),
                      letterSpacing: -0.03 * ghostFontSize,
                    ).copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),

          // Online badge — top-right
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              left: false,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: ValueListenableBuilder<int>(
                  valueListenable: onlineCount,
                  builder: (_, count, _) =>
                      OnlineCountBadge(count: count, useSeniorsLabel: true),
                ),
              ),
            ),
          ),

          // Brand content — logo and wordmark
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Logo
                    ClipOval(
                      child: Image.asset(
                        'assets/icons/tander_icon.png',
                        width: 56,
                        height: 56,
                        semanticLabel: 'Tander logo',
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Wordmark
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

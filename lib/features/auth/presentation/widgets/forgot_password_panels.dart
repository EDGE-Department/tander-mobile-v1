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
        color: AppColors.card,
        borderRadius: isWide
            ? BorderRadius.circular(36)
            : const BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(36),
              ),
        boxShadow: isWide
            ? const [
                BoxShadow(
                  color: Color(0x29E6A032),
                  blurRadius: 60,
                  offset: Offset(0, 20),
                ),
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 100,
                  offset: Offset(0, 40),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isWide) _buildDragHandle(),
          if (isWide) _buildAccentBar(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 28,
              isWide ? 32 : 8,
              isWide ? 40 : 28,
              isWide ? 32 : 28,
            ),
            child: isCodeSent ? successContent : formContent,
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }

  Widget _buildAccentBar() {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
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
    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          LoginHeaderBackground(headerHeight: headerHeight + headerOverlap),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildLogoRow(),
                    const SizedBox(height: 12),
                    _buildHeading(),
                    const SizedBox(height: 6),
                    _buildSubtitle(),
                    const SizedBox(height: 4),
                    _buildTagline(),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<int>(
                      valueListenable: onlineCount,
                      builder: (_, count, _) =>
                          OnlineCountBadge(count: count),
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
          'assets/icons/tander_logo.png',
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
      'Account Recovery',
      style: AppTypography.h1.copyWith(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Regain access in 3 simple steps',
      style: AppTypography.bodySm.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.75),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTagline() {
    return Text(
      'Ligtas at madali \u00B7 Safe and easy',
      style: AppTypography.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: Colors.white.withValues(alpha: 0.45),
      ),
      textAlign: TextAlign.center,
    );
  }
}

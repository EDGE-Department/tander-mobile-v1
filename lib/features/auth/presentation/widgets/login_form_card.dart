import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_form_inputs.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_submit_button.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Border radius for the form panel top corners (web: `rounded-t-[36px]`).
const double _panelTopRadius = 36;

/// Drag handle gradient matching web's `var(--gradient-drag-handle)`.
const LinearGradient _dragHandleGradient = LinearGradient(
  colors: [AppColors.primary, AppColors.secondary],
);

/// Brand icon gradient matching web's `var(--gradient-primary-button)`.
const LinearGradient _brandIconGradient = LinearGradient(
  begin: Alignment(-0.7, -1),
  end: Alignment(0.7, 1),
  colors: [Color(0xFFE67E22), Color(0xFFD06A18)],
);

/// Divider color matching web's `rgba(230,126,34,0.14)`.
const Color _dividerColor = Color(0x24E67E22);

// ── Main widget ─────────────────────────────────────────────────────

/// The white form panel that overlaps the header gradient,
/// containing brand mark, heading, input fields, submit button,
/// and download prompt.
///
/// Matches the web's `<LoginFormCard />` component for the mobile
/// layout: `rounded-t-[36px]`, white background, inner shadow,
/// drag handle, brand row, heading, form, divider, download CTA.
class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isPasswordVisible,
    required this.rememberMe,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onToggleRememberMe,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onlineCount,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isPasswordVisible;
  final bool rememberMe;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRememberMe;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: isWide
            ? BorderRadius.circular(_panelTopRadius)
            : const BorderRadius.only(
                topLeft: Radius.circular(_panelTopRadius),
                topRight: Radius.circular(_panelTopRadius),
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
            : const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 28,
                  offset: Offset(0, -8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _BrandHeader(onlineCount: onlineCount)
                    .animate()
                    .fadeIn(
                      duration: 550.ms,
                      delay: 420.ms,
                      curve: AppCurves.premiumEase,
                    )
                    .slideY(begin: 0.08, curve: AppCurves.premiumEase),
                const SizedBox(height: 28),
                const _HeadingBlock()
                    .animate()
                    .fadeIn(
                      duration: 550.ms,
                      delay: 510.ms,
                      curve: AppCurves.premiumEase,
                    )
                    .slideY(begin: 0.08, curve: AppCurves.premiumEase),
                const SizedBox(height: 24),
                if (errorMessage != null) ...[
                  _ApiErrorBanner(message: errorMessage!),
                  const SizedBox(height: 16),
                ],
                _buildForm()
                    .animate()
                    .fadeIn(
                      duration: 550.ms,
                      delay: 600.ms,
                      curve: AppCurves.premiumEase,
                    )
                    .slideY(begin: 0.06, curve: AppCurves.premiumEase),
                const SizedBox(height: 24),
                const Divider(color: _dividerColor, height: 1)
                    .animate()
                    .fadeIn(delay: 780.ms, duration: 400.ms),
                const SizedBox(height: 20),
                const _DownloadPrompt()
                    .animate()
                    .fadeIn(
                      duration: 550.ms,
                      delay: 870.ms,
                      curve: AppCurves.premiumEase,
                    )
                    .slideY(begin: 0.08, curve: AppCurves.premiumEase),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LoginTextField(
            label: 'Email or phone number',
            hint: 'name@email.com or 09XXXXXXXXX',
            controller: emailController,
            focusNode: emailFocusNode,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateIdentifier,
          ),
          const SizedBox(height: 16),
          LoginPasswordField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            isPasswordVisible: isPasswordVisible,
            onToggleVisibility: onTogglePassword,
            onForgotPassword: onForgotPassword,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          LoginRememberMeCheckbox(
            isChecked: rememberMe,
            onToggle: onToggleRememberMe,
          ),
          const SizedBox(height: 20),
          LoginSubmitButton(isLoading: isLoading, onPressed: onSubmit),
          const SizedBox(height: 12),
          const _PrivacyNotice(),
        ],
      ),
    );
  }

  static String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email or phone number';
    }
    return null;
  }
}

// ── Drag handle ─────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            gradient: _dragHandleGradient,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

// ── Brand header ────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onlineCount});

  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: _brandIconGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59E67E22), // rgba(230,126,34,0.35)
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Tander',
              style: AppTypography.brandWordmark(
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        OnlineCountBadge(count: onlineCount, isLightBackground: true),
      ],
    );
  }
}

// ── Heading block ───────────────────────────────────────────────────

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back',
          style: AppTypography.displayLg.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your community is waiting \u2014 let\u2019s get you back in.',
          style: AppTypography.body.copyWith(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Nandito na kami \u00B7 We\u2019re here for you',
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
            color: AppColors.primaryAccessible.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

// ── API error banner ────────────────────────────────────────────────

class _ApiErrorBanner extends StatelessWidget {
  const _ApiErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDurations.base,
      curve: AppCurves.premiumEase,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.20),
          ),
        ),
        child: Text(
          message,
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}

// ── Privacy notice ──────────────────────────────────────────────────

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user,
          size: 13,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Your privacy and safety are our top priority',
          style: AppTypography.caption.copyWith(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Download prompt ─────────────────────────────────────────────────

class _DownloadPrompt extends StatelessWidget {
  const _DownloadPrompt();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.phone_android,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textMuted,
                height: 1.4,
              ),
              children: const [
                TextSpan(text: 'New to Tander? '),
                TextSpan(
                  text: 'Download the app',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' to get started'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

// -- Constants ---------------------------------------------------------------

const int _resendCooldownSeconds = 60;

/// Email verification screen shown after registration.
///
/// Displays a large email icon, tells the user to check their inbox,
/// and provides resend + back-to-login actions. Expects route extras:
/// `{'email': String}` or reads email from the current session.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isResending = false;
  bool _hasResent = false;
  int _secondsLeft = 0;
  Timer? _countdownTimer;

  String _email = '';

  bool get _canResend => _secondsLeft == 0 && !_isResending && !_hasResent;

  // -- Lifecycle ------------------------------------------------------------

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extras = GoRouterState.of(context).extra;
    if (extras is Map<String, String>) {
      _email = extras['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  // -- Timer ----------------------------------------------------------------

  void _startCooldown() {
    _countdownTimer?.cancel();
    _secondsLeft = _resendCooldownSeconds;
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;
        setState(() {
          _secondsLeft = (_secondsLeft - 1).clamp(0, _resendCooldownSeconds);
        });
        if (_secondsLeft == 0) {
          _countdownTimer?.cancel();
        }
      },
    );
  }

  // -- Actions --------------------------------------------------------------

  Future<void> _resendVerification() async {
    if (!_canResend || _email.isEmpty) return;

    setState(() => _isResending = true);

    final repository = ref.read(authRepositoryProvider);
    final resendResult =
        await repository.resendEmailVerification(email: _email);

    if (!mounted) return;

    resendResult.when(
      success: (_) {
        setState(() {
          _isResending = false;
          _hasResent = true;
        });
        _startCooldown();
      },
      failure: (exception) {
        setState(() => _isResending = false);
        TanderToastOverlay.show(
          context,
          TanderToastData(
            message: exception.userMessage,
            variant: TanderToastVariant.error,
          ),
        );
      },
    );
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEmailIcon(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildHeading(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildActions(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSupportLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Email icon -----------------------------------------------------------

  Widget _buildEmailIcon() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: AppDurations.entrance,
      curve: AppCurves.premiumEase,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight,
              AppColors.primary.withValues(alpha: 0.15),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33E67E22),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.email_rounded,
          size: 48,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // -- Heading --------------------------------------------------------------

  Widget _buildHeading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Verify your email',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            children: [
              const TextSpan(text: 'We sent a verification link to '),
              if (_email.isNotEmpty)
                TextSpan(
                  text: _email,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Click the link in the email to activate your account. '
          "Check your spam folder if you don't see it.",
          style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // -- Actions --------------------------------------------------------------

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasResent) _buildResentConfirmation() else _buildResendButton(),
        const SizedBox(height: AppSpacing.sm),
        TanderButton(
          label: 'Return to Sign In',
          onPressed: () => context.go(AppRoutes.login),
          variant: TanderButtonVariant.ghost,
          icon: Icons.login_rounded,
        ),
      ],
    );
  }

  Widget _buildResendButton() {
    final String label;
    if (_secondsLeft > 0) {
      label = 'Resend in ${_secondsLeft}s';
    } else {
      label = 'Resend Verification Email';
    }

    return TanderButton(
      label: label,
      onPressed: _canResend ? _resendVerification : null,
      variant: TanderButtonVariant.outline,
      isLoading: _isResending,
      isDisabled: !_canResend,
      icon: Icons.refresh_rounded,
    );
  }

  Widget _buildResentConfirmation() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Verification email resent -- please check your inbox.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Support link ---------------------------------------------------------

  Widget _buildSupportLink() {
    return Text.rich(
      TextSpan(
        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        children: const [
          TextSpan(text: 'Having trouble? Contact '),
          TextSpan(
            text: 'support@tander.com',
            style: TextStyle(
              color: AppColors.primaryAccessible,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

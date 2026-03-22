import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/otp_digit_boxes.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/otp_verified_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/resend_timer.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// OTP verification type passed via route extras.
const String otpTypeRegistration = 'REGISTRATION';
const String otpTypePasswordReset = 'PASSWORD_RESET';

/// OTP verification screen with 6 individual digit input boxes.
///
/// Expects route extras: `{'email': String, 'type': String}`.
/// Auto-submits when all 6 digits are entered. Includes a resend-code
/// countdown timer and shake animation on error.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final _otpBoxesKey = GlobalKey<OtpDigitBoxesState>();
  final _resendTimerKey = GlobalKey<ResendTimerState>();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  bool _isVerifying = false;
  bool _isVerified = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isResending = false;

  int _filledDigitCount = 0;

  String _email = '';
  bool _isRegistration = false;

  // -- Lifecycle ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extras = GoRouterState.of(context).extra;
    if (extras is Map<String, String>) {
      _email = extras['email'] ?? '';
      _isRegistration = extras['type'] == otpTypeRegistration;
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // -- Actions --------------------------------------------------------------

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < otpLength || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final verifyResult = _isRegistration
        ? await repository.verifyRegistrationOtp(email: _email, otp: otp)
        : await repository.verifyResetOtp(email: _email, otp: otp);

    if (!mounted) return;

    verifyResult.when(
      success: (_) {
        setState(() {
          _isVerifying = false;
          _isVerified = true;
        });
        final destination =
            _isRegistration ? AppRoutes.profileSetup : AppRoutes.login;
        Future<void>.delayed(
          const Duration(milliseconds: 2200),
          () {
            if (mounted) context.go(destination);
          },
        );
      },
      failure: (exception) {
        setState(() {
          _isVerifying = false;
          _hasError = true;
          _errorMessage = exception.userMessage;
        });
        _shakeController.forward(from: 0);
      },
    );
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);

    final repository = ref.read(authRepositoryProvider);
    final resendResult =
        await repository.requestPasswordReset(email: _email);

    if (!mounted) return;

    resendResult.when(
      success: (_) {
        setState(() {
          _isResending = false;
          _hasError = false;
          _errorMessage = null;
        });
        _resendTimerKey.currentState?.restart();
        _otpBoxesKey.currentState?.clearAll();
        TanderToastOverlay.show(
          context,
          const TanderToastData(
            message: 'A new code has been sent to your email.',
            variant: TanderToastVariant.success,
          ),
        );
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
          child: Column(
            children: [
              _buildBackButton(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child:
                        _isVerified ? _buildVerifiedState() : _buildOtpForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          top: AppSpacing.xs,
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          iconSize: 24,
          color: AppColors.textStrong,
          tooltip: 'Go back',
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchComfortable,
            minHeight: AppSpacing.touchComfortable,
          ),
        ),
      ),
    );
  }

  // -- OTP form body --------------------------------------------------------

  Widget _buildOtpForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconHero(),
        const SizedBox(height: AppSpacing.lg),
        _buildHeading(),
        const SizedBox(height: AppSpacing.xl),
        _buildErrorAlert(),
        OtpDigitBoxes(
          key: _otpBoxesKey,
          onComplete: _verifyOtp,
          shakeAnimation: _shakeAnimation,
          hasError: _hasError,
          isEnabled: !_isVerifying,
          onDigitCountChanged: (count) {
            setState(() => _filledDigitCount = count);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _buildProgressBar(),
        const SizedBox(height: AppSpacing.lg),
        _buildVerifyButton(),
        const SizedBox(height: AppSpacing.lg),
        ResendTimer(
          key: _resendTimerKey,
          onResend: _resendCode,
          isResending: _isResending,
        ),
      ],
    );
  }

  Widget _buildIconHero() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [Color(0xFF0F9D94), Color(0xFF0B7D73)],
        ),
        borderRadius: AppRadius.borderXl,
        boxShadow: const [
          BoxShadow(
            color: Color(0x730F9D94),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_rounded,
        size: 36,
        color: AppColors.textInverse,
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter your code',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _email.isNotEmpty ? _email : 'your email',
                style: AppTypography.body.copyWith(
                  color: AppColors.textStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorAlert() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.danger,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _errorMessage!,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _filledDigitCount / otpLength;
    return ClipRRect(
      borderRadius: AppRadius.borderFull,
      child: SizedBox(
        height: 4,
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return TanderButton(
      label: 'Verify Code',
      onPressed: _filledDigitCount < otpLength || _isVerifying
          ? null
          : () => _verifyOtp(
                _otpBoxesKey.currentState?.otpValue ?? '',
              ),
      isLoading: _isVerifying,
      isDisabled: _filledDigitCount < otpLength,
      icon: Icons.check_rounded,
      iconPosition: IconPosition.trailing,
    );
  }

  // -- Verified state -------------------------------------------------------

  Widget _buildVerifiedState() {
    return OtpVerifiedState(isRegistration: _isRegistration);
  }
}

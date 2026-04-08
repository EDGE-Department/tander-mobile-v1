import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/registration_step_dots.dart';
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
/// Matches the web's mobile layout: warm gradient background, icon hero,
/// heading with contact, OTP boxes, progress bar, verify button, resend timer.
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
  String _phone = '';
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
      _phone = extras['phone'] ?? '';
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

    if (_isRegistration) {
      await _handleRegistrationOtp(otp, repository);
    } else {
      final verifyResult = await repository.verifyResetOtp(
        email: _email.isNotEmpty ? _email : null,
        phone: _phone.isNotEmpty ? _phone : null,
        otp: otp,
      );
      if (!mounted) return;
      verifyResult.when(
        success: (resetToken) {
          setState(() {
            _isVerifying = false;
            _isVerified = true;
          });
          Future<void>.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              context.go(
                AppRoutes.resetPassword,
                extra: {
                  'email': _email,
                  'phone': _phone,
                  'resetToken': resetToken,
                },
              );
            }
          });
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
  }

  Future<void> _handleRegistrationOtp(
    String otp,
    AuthRepository repository,
  ) async {
    // Step 1: Verify OTP via Twilio
    final verifyResult = await repository.verifyRegistrationOtp(
      email: _email.isNotEmpty ? _email : null,
      phone: _phone.isNotEmpty ? _phone : null,
      otp: otp,
    );

    if (!mounted) return;

    verifyResult.when(
      success: (isValid) async {
        if (!isValid) {
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage = 'Invalid verification code. Please try again.';
          });
          _shakeController.forward(from: 0);
          return;
        }

        // Step 2: OTP verified — now create the account
        final secureStorage = ref.read(secureStorageProvider);
        final pending = await secureStorage.readPendingRegistration();

        if (pending.password == null || pending.auditId == null) {
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage =
                'Registration data expired. Please start over.';
          });
          return;
        }

        final email = (pending.email ?? _email).trim();
        final phone = (pending.phone ?? _phone).trim();

        await ref.read(authNotifierProvider.notifier).register(
              email: email.isNotEmpty ? email : null,
              phone: phone.isNotEmpty ? phone : null,
              password: pending.password!,
              auditId: pending.auditId!,
            );

        if (!mounted) return;

        // Auto-login to get JWT tokens (register doesn't issue them)
        final contact = email.isNotEmpty ? email : phone;
        await ref.read(authNotifierProvider.notifier).signIn(
              email: contact,
              password: pending.password!,
            );

        if (!mounted) return;

        // Clean up pending data
        await secureStorage.clearPendingRegistration();

        setState(() {
          _isVerifying = false;
          _isVerified = true;
        });

        // Router redirect will handle navigation to profile setup
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
    final resendResult = _isRegistration
        ? await repository.sendRegistrationOtp(
            email: _email.isNotEmpty ? _email : null,
            phone: _phone.isNotEmpty ? _phone : null,
          )
        : await repository.requestPasswordReset(
            email: _email.isNotEmpty ? _email : null,
            phone: _phone.isNotEmpty ? _phone : null,
          );

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

  // Bottom color of authGradient — paint the system nav bar to match.
  static const Color _navBarColor = Color(0xFF20BF68);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = resolveHeaderHeight(screenHeight);

    return Scaffold(
      backgroundColor: _navBarColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: authGradient),
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(headerHeight),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: _buildWhiteSheet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double headerHeight) {
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
            child: const IgnorePointer(child: AuthHeaderScene()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Column(
                children: [
                  _buildNavRow(),
                  const Spacer(),
                  Image.asset(
                    'assets/icons/tander_icon.png',
                    width: 52,
                    height: 52,
                    semanticLabel: 'Tander logo',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow() {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pop(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const Spacer(),
        if (_isRegistration)
          Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Step 2 of 4',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildWhiteSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const AuthSheetHandle(),
            const SizedBox(height: 4),
            if (_isRegistration)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Center(
                  child: RegistrationStepDots(
                    currentStep: 2,
                    totalSteps: 4,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: _isVerified ? _buildVerifiedState() : _buildOtpForm(),
              ),
            ),
          ],
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

  /// Icon hero: shield icon, teal gradient
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
        Icons.verified_user,
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
                text: _email.isNotEmpty
                    ? _email
                    : _phone.isNotEmpty
                        ? _phone
                        : 'your contact',
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

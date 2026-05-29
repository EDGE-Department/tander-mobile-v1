import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/domain/repositories/auth_repository.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_error_display.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/otp_digit_boxes.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/otp_verified_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/resend_timer.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/utils/launch_support_email.dart';
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

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final _otpBoxesKey = GlobalKey<OtpDigitBoxesState>();
  final _resendTimerKey = GlobalKey<ResendTimerState>();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  bool _isVerifying = false;
  bool _isVerified = false;
  bool _hasError = false;
  String? _errorMessage;
  NetworkException? _offlineError;
  bool _isResending = false;
  String? _lastOtp;

  int _filledDigitCount = 0;
  int _consecutiveNonNetworkFailures = 0;

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
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
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

  // Honor OS-level "reduce motion" by skipping the error-shake animation.
  // We jump straight to the error state (already conveyed by the red boxes +
  // banner) instead of running the controller.
  void _triggerErrorShake() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_shakeController.forward(from: 0));
  }

  // -- Actions --------------------------------------------------------------

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < otpLength || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = null;
      _offlineError = null;
      _lastOtp = otp;
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
            _consecutiveNonNetworkFailures = 0;
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
          if (exception is NetworkException) {
            setState(() {
              _isVerifying = false;
              _offlineError = exception;
            });
            return;
          }
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage = exception.userMessage;
            _consecutiveNonNetworkFailures++;
          });
          _triggerErrorShake();
        },
      );
    }
  }

  void _retryOtp() {
    if (_lastOtp == null) return;
    setState(() => _offlineError = null);
    _verifyOtp(_lastOtp!);
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

    unawaited(
      verifyResult.when(
      success: (isValid) async {
        if (!isValid) {
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage = 'Invalid verification code. Please try again.';
            _consecutiveNonNetworkFailures++;
          });
          _triggerErrorShake();
          return;
        }

        // Step 2: OTP verified — now create the account
        final secureStorage = ref.read(secureStorageProvider);
        final pending = await secureStorage.readPendingRegistration();

        if (pending.password == null || pending.auditId == null) {
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage = 'Registration data expired. Please start over.';
          });
          return;
        }

        final email = (pending.email ?? _email).trim();
        final phone = (pending.phone ?? _phone).trim();

        await ref
            .read(authNotifierProvider.notifier)
            .register(
              email: email.isNotEmpty ? email : null,
              phone: phone.isNotEmpty ? phone : null,
              password: pending.password!,
              auditId: pending.auditId!,
            );

        if (!mounted) return;

        final stateAfterRegister = ref.read(authNotifierProvider);
        if (stateAfterRegister is AuthError) {
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage = stateAfterRegister.exception.userMessage;
            _consecutiveNonNetworkFailures++;
          });
          _triggerErrorShake();
          return;
        }

        // Auto-login to get JWT tokens (register doesn't issue them)
        final contact = email.isNotEmpty ? email : phone;
        await ref
            .read(authNotifierProvider.notifier)
            .signIn(email: contact, password: pending.password!);

        if (!mounted) return;

        final stateAfterSignIn = ref.read(authNotifierProvider);
        if (stateAfterSignIn is AuthError) {
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _errorMessage = stateAfterSignIn.exception.userMessage;
            _consecutiveNonNetworkFailures++;
          });
          _triggerErrorShake();
          return;
        }

        // Clean up pending data
        await secureStorage.clearPendingRegistration();

        setState(() {
          _isVerifying = false;
          _isVerified = true;
          _consecutiveNonNetworkFailures = 0;
        });

        // Router redirect will handle navigation to profile setup
      },
      failure: (exception) async {
        if (exception is NetworkException) {
          setState(() {
            _isVerifying = false;
            _offlineError = exception;
          });
          return;
        }
        setState(() {
          _isVerifying = false;
          _hasError = true;
          _errorMessage = exception.userMessage;
        });
        unawaited(_shakeController.forward(from: 0));
      },
    ),
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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: _navBarColor,
      resizeToAvoidBottomInset: true,
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
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding + 8),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ghostFontSize = (screenWidth * 0.24).clamp(72.0, 96.0);
    final wordmarkSize = (screenWidth * 0.14).clamp(48.0, 60.0);

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ghost "Tander" wordmark
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Column(
                children: [
                  _buildNavRow(),
                  const Spacer(),
                  // Logo
                  ClipOval(
                    child: Image.asset(
                      'assets/icons/tander_icon.png',
                      width: 48,
                      height: 48,
                      semanticLabel: 'Tander logo',
                    ),
                  ),
                  // White "Tander" wordmark with shadow
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
        ],
      ),
    );
  }

  Widget _buildNavRow() {
    return Row(
      children: [
        Semantics(
          label: 'Go back',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        if (_isRegistration)
          StepBadgeEntry(
            child: Container(
              padding: const EdgeInsets.all(1.2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Step 2 of 5',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
          ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildWhiteSheet() {
    final borderRadius = BorderRadius.circular(32);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF8),
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.45,
                  child: CustomPaint(
                    painter: ParchmentDotGridPainter(spacing: 24),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Orange accent bar at top
                Container(
                  height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF07040), Color(0xFFE86035)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius.topLeft,
                  topRight: borderRadius.topRight,
                ),
              ),
            ),
            // Scrollable form content + sticky footer (Verify + Resend)
            if (_isVerified)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: _buildVerifiedState(),
                ),
              )
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildOtpForm(),
                ),
              ),
              // Sticky Verify button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Builder(
                  builder: (context) {
                    final isEnabled =
                        _filledDigitCount >= otpLength && !_isVerifying;
                    return TanderButton(
                      label: 'Verify Code',
                      onPressed: isEnabled
                          ? () {
                              HapticFeedback.lightImpact();
                              _verifyOtp(
                                _otpBoxesKey.currentState?.otpValue ?? '',
                              );
                            }
                          : null,
                      variant: TanderButtonVariant.primary,
                      size: TanderButtonSize.normal,
                      isLoading: _isVerifying,
                      icon: Icons.check_rounded,
                      iconPosition: IconPosition.trailing,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: ResendTimer(
                  key: _resendTimerKey,
                  onResend: _resendCode,
                  isResending: _isResending,
                ),
              ),
            ],
              ],
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
        const SizedBox(height: 16),
        _buildHeading(),
        const SizedBox(height: 20),
        _buildErrorAlert(),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'Enter the 6-digit code we just sent you.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'It checks automatically once you enter all 6 digits.',
            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
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
        const SizedBox(height: 16),
        _buildProgressBar(),
      ],
    );
  }

  /// Icon hero: shield icon with orange gradient matching login button
  Widget _buildIconHero() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59E67E22),
            blurRadius: 24,
            offset: Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: const Icon(Icons.sms_outlined, size: 32, color: Colors.white),
    );
  }

  Widget _buildHeading() {
    final contact = _phone.isNotEmpty ? _phone : _email;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Verify Your Contact',
          style: AppTypography.h1.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a 6-digit code to',
          style: AppTypography.body.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            contact.isNotEmpty ? contact : 'your contact',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorAlert() {
    // Offline-retry banner (sticky) takes precedence over the generic banner.
    if (_offlineError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AuthErrorDisplay.banner(
          message: _offlineError!.userMessage,
          autoDismiss: false,
          onRetry: _retryOtp,
          onDismiss: () => setState(() => _offlineError = null),
        ),
      );
    }
    if (_errorMessage == null) return const SizedBox.shrink();
    // Banner tier: see AuthErrorDisplay docs for tier policy.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthErrorDisplay.banner(
            message: _errorMessage!,
            onDismiss: () => setState(() {
              _errorMessage = null;
              _hasError = false;
            }),
          ),
          if (_consecutiveNonNetworkFailures >= 3) ...[
            const SizedBox(height: 12),
            Center(
              child: Semantics(
                button: true,
                label: 'Contact support',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => launchSupportEmail(
                    context,
                    subject: 'OTP verification issue',
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Center(
                      child: Text(
                        'Having trouble? Contact support',
                        style: AppTypography.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _filledDigitCount / otpLength;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              width: double.infinity,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0
                      ? const Color(0xFF10B981) // Green when complete
                      : const Color(0xFFE67E22), // Orange while typing
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_filledDigitCount of $otpLength digits entered',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -- Verified state -------------------------------------------------------

  Widget _buildVerifiedState() {
    return OtpVerifiedState(isRegistration: _isRegistration);
  }
}

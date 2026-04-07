import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/constants/routes.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/data_privacy_sheet.dart';
import '../../../../shared/widgets/fade_slide_transition.dart';
import '../../../../shared/widgets/terms_conditions_sheet.dart';
import '../../data/registration_constants.dart';
import '../../data/registration_method.dart';
import '../notifiers/auth_notifier.dart';
import '../providers/auth_providers.dart';
import '../states/auth_state.dart';
import 'agreement_checkboxes.dart';
import 'agreement_required_dialog.dart';
import 'availability_suffix_icon.dart';
import 'method_selector.dart';
import 'password_requirements_checklist.dart';

/// SignUp form card with email/phone registration.
class SignUpFormCard extends ConsumerStatefulWidget {
  final AnimationController entrance;
  final VoidCallback onSignIn;
  final bool isBottomSheet;

  const SignUpFormCard({
    super.key,
    required this.entrance,
    required this.onSignIn,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<SignUpFormCard> createState() => _SignUpFormCardState();
}

class _SignUpFormCardState extends ConsumerState<SignUpFormCard>
    with TickerProviderStateMixin {
  final _contactCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _contactFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  RegistrationMethod _method = RegistrationMethod.email;

  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _contactError;
  String? _passwordError;
  String? _confirmError;

  AvailabilityStatus _emailAvailability = AvailabilityStatus.idle;
  Timer? _emailDebounce;
  AvailabilityStatus _phoneAvailability = AvailabilityStatus.idle;
  Timer? _phoneDebounce;
  bool _showPasswordChecklist = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  late final AnimationController _scaleController;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 220),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.22, end: 0.42).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _phoneDebounce?.cancel();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _contactFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --- Availability Checks ---

  void _onEmailChanged(String value) {
    if (_contactError != null) setState(() => _contactError = null);
    if (_method != RegistrationMethod.email) return;

    _emailDebounce?.cancel();
    final trimmed = value.trim();

    if (Validators.email(trimmed) != null) {
      if (_emailAvailability != AvailabilityStatus.idle) {
        setState(() => _emailAvailability = AvailabilityStatus.idle);
      }
      return;
    }

    setState(() => _emailAvailability = AvailabilityStatus.checking);

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        final result = await ref
            .read(authRepositoryProvider)
            .checkEmailAvailability(email: trimmed);
        if (!mounted || _contactCtrl.text.trim() != trimmed) return;
        final isAvailable = result.valueOrNull ?? false;
        setState(() {
          _emailAvailability = isAvailable
              ? AvailabilityStatus.available
              : AvailabilityStatus.taken;
          if (!isAvailable) {
            _contactError =
                'This email is already registered. Sign in to complete your profile.';
          }
        });
      } catch (_) {
        if (mounted) {
          setState(() => _emailAvailability = AvailabilityStatus.idle);
        }
      }
    });
  }

  void _onPhoneChanged(String value) {
    if (_contactError != null) setState(() => _contactError = null);

    _phoneDebounce?.cancel();
    final trimmed = value.replaceAll(RegExp(r'[\s\-]'), '');

    if (trimmed.length != RegistrationConstants.phoneDigitLength ||
        !trimmed.startsWith('9')) {
      if (_phoneAvailability != AvailabilityStatus.idle) {
        setState(() => _phoneAvailability = AvailabilityStatus.idle);
      }
      return;
    }

    setState(() => _phoneAvailability = AvailabilityStatus.checking);

    _phoneDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final fullNumber = '${RegistrationConstants.phoneCountryCode}$trimmed';
      try {
        final result = await ref
            .read(authRepositoryProvider)
            .checkPhoneAvailability(phone: fullNumber);
        if (!mounted ||
            _contactCtrl.text.replaceAll(RegExp(r'[\s\-]'), '') != trimmed) {
          return;
        }
        final isAvailable = result.valueOrNull ?? false;
        setState(() {
          _phoneAvailability = isAvailable
              ? AvailabilityStatus.available
              : AvailabilityStatus.taken;
          if (!isAvailable) {
            _contactError =
                'This phone number is already registered. Sign in to complete your profile.';
          }
        });
      } catch (_) {
        if (mounted) {
          setState(() => _phoneAvailability = AvailabilityStatus.idle);
        }
      }
    });
  }

  void _onPasswordChanged(String value) {
    if (_passwordError != null) setState(() => _passwordError = null);
    if (!_showPasswordChecklist && value.isNotEmpty) {
      setState(() => _showPasswordChecklist = true);
    }
    setState(() {});
  }

  void _onConfirmChanged(String value) {
    if (_confirmError != null) setState(() => _confirmError = null);
    setState(() {});
  }

  // --- Validation ---

  bool get _canSubmit {
    if (_method == RegistrationMethod.email) {
      if (_emailAvailability == AvailabilityStatus.checking) return false;
      if (_emailAvailability == AvailabilityStatus.taken) return false;
    }
    if (_method == RegistrationMethod.phone) {
      if (_phoneAvailability == AvailabilityStatus.checking) return false;
      if (_phoneAvailability == AvailabilityStatus.taken) return false;
    }
    return true;
  }

  bool _validate() {
    _contactError = null;
    _passwordError = null;
    _confirmError = null;

    final contact = _contactCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    bool isValid = true;

    if (_method == RegistrationMethod.phone) {
      final digits = contact.replaceAll(RegExp(r'\D'), '');
      if (digits.isEmpty) {
        _contactError = 'Please enter your mobile number';
        isValid = false;
      } else if (digits.length != RegistrationConstants.phoneDigitLength) {
        _contactError = 'Please enter all 10 digits';
        isValid = false;
      } else if (!digits.startsWith('9')) {
        _contactError = 'Philippine numbers start with 9';
        isValid = false;
      } else if (_phoneAvailability == AvailabilityStatus.taken) {
        _contactError = 'This phone number is already registered';
        isValid = false;
      }
    } else {
      final emailError = Validators.email(contact);
      if (emailError != null) {
        _contactError = emailError;
        isValid = false;
      } else if (_emailAvailability == AvailabilityStatus.taken) {
        _contactError = 'This email is already registered';
        isValid = false;
      }
    }

    final pwError = Validators.password(password);
    if (pwError != null) {
      _passwordError = pwError;
      isValid = false;
    }

    final cfError = Validators.confirmPassword(confirm, password);
    if (cfError != null) {
      _confirmError = cfError;
      isValid = false;
    }

    if (!isValid) setState(() {});
    return isValid;
  }

  // --- Submit ---

  Future<void> _handleSignUp() async {
    if (_isLoading || !_validate()) return;

    if (!_agreedToTerms || !_agreedToPrivacy) {
      await _showAgreementRequired();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contact = _contactCtrl.text.trim();
      final password = _passwordCtrl.text;

      // Read auditId from secure storage
      final auditIdResult =
          await ref.read(secureStorageProvider).readAuditId();
      final auditId = auditIdResult.valueOrNull;

      if (auditId == null || auditId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'ID verification is required. Please go back and verify your identity.';
        });
        return;
      }

      final secureStorage = ref.read(secureStorageProvider);
      final isPhone = _method == RegistrationMethod.phone;
      final normalizedContact = isPhone
          ? '${RegistrationConstants.phoneCountryCode}${contact.replaceAll(RegExp(r'\D'), '')}'
          : contact;

      // Check if OTP was already sent for this contact (user pressed back)
      final pending = await secureStorage.readPendingRegistration();
      final pendingContact = pending.email ?? pending.phone ?? '';
      if (pendingContact == normalizedContact &&
          pending.password != null &&
          pending.auditId != null) {
        // Verify the email/phone is still available before resuming
        final repository = ref.read(authRepositoryProvider);
        final isAvailable = isPhone
            ? await repository.checkPhoneAvailability(phone: normalizedContact)
            : await repository.checkEmailAvailability(email: normalizedContact);
        final available = isAvailable.valueOrNull ?? false;
        if (!available) {
          await secureStorage.clearPendingRegistration();
          setState(() {
            _isLoading = false;
            _errorMessage =
                'This ${isPhone ? "phone number" : "email"} is already registered. Please sign in instead.';
          });
          return;
        }
        // OTP already sent — go directly to OTP screen without re-sending
        setState(() => _isLoading = false);
        if (mounted) {
          context.push(
            AppRoutes.otpVerification,
            extra: {
              'email': isPhone ? '' : normalizedContact,
              'phone': isPhone ? normalizedContact : '',
              'type': 'REGISTRATION',
            },
          );
        }
        return;
      }

      // Store credentials locally — account is NOT created until OTP verified
      await secureStorage.savePendingRegistration(
        email: isPhone ? null : normalizedContact,
        phone: isPhone ? normalizedContact : null,
        password: password,
        auditId: auditId,
      );

      // Send OTP via Twilio
      final repository = ref.read(authRepositoryProvider);
      final sendResult = await repository.sendRegistrationOtp(
        email: isPhone ? null : normalizedContact,
        phone: isPhone ? normalizedContact : null,
      );

      if (!mounted) return;

      sendResult.when(
        success: (_) {
          setState(() => _isLoading = false);
          context.push(
            AppRoutes.otpVerification,
            extra: {
              'email': isPhone ? '' : normalizedContact,
              'phone': isPhone ? normalizedContact : '',
              'type': 'REGISTRATION',
            },
          );
        },
        failure: (exception) {
          setState(() {
            _isLoading = false;
            _errorMessage = exception.userMessage;
          });
        },
      );
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _showAgreementRequired() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AgreementRequiredDialog(
        onViewTerms: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) TermsConditionsSheet.show(context);
          });
        },
        onViewPrivacy: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) DataPrivacySheet.show(context);
          });
        },
        onDecline: () => Navigator.pop(context),
        onAgree: () {
          setState(() {
            _agreedToTerms = true;
            _agreedToPrivacy = true;
          });
          Navigator.pop(context);
          _handleSignUp();
        },
      ),
    );
  }

  void _onTapDown(TapDownDetails _) {
    if (!_isLoading && _canSubmit) _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails _) => _scaleController.forward();
  void _onTapCancel() => _scaleController.forward();

  @override
  Widget build(BuildContext context) {
    final columnContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error banner
        if (_errorMessage != null) _errorBanner(),

        // Card intro
        _cardIntro(),
        const SizedBox(height: 20),

        // Form fields
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MethodSelector(
                selected: _method,
                onChanged: (method) {
                  setState(() {
                    _method = method;
                    _contactError = null;
                    _emailAvailability = AvailabilityStatus.idle;
                    _phoneAvailability = AvailabilityStatus.idle;
                    _contactCtrl.clear();
                  });
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              if (_method == RegistrationMethod.phone)
                _buildTextField(
                  label: 'Mobile Number',
                  hint: '912 345 6789',
                  controller: _contactCtrl,
                  focusNode: _contactFocus,
                  keyboardType: TextInputType.phone,
                  errorText: _contactError,
                  onChanged: _onPhoneChanged,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  enabled: !_isLoading,
                  prefixIcon: _phonePrefix(),
                  suffixIcon: AvailabilitySuffixIcon(status: _phoneAvailability),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      RegistrationConstants.phoneDigitLength,
                    ),
                  ],
                )
              else
                _buildTextField(
                  label: 'Email',
                  hint: 'your@email.com',
                  controller: _contactCtrl,
                  focusNode: _contactFocus,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _contactError,
                  onChanged: _onEmailChanged,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  enabled: !_isLoading,
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF9CA3AF)),
                  suffixIcon: AvailabilitySuffixIcon(status: _emailAvailability),
                ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Password',
                hint: '8+ characters with uppercase and number',
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                errorText: _passwordError,
                onChanged: _onPasswordChanged,
                onSubmitted: (_) => _confirmFocus.requestFocus(),
                enabled: !_isLoading,
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 16),
              if (_showPasswordChecklist) ...[
                PasswordRequirementsChecklist(
                  password: _passwordCtrl.text,
                  confirmPassword: _confirmCtrl.text.isNotEmpty
                      ? _confirmCtrl.text
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              _buildTextField(
                label: 'Confirm Password',
                hint: 'Re-enter password',
                controller: _confirmCtrl,
                focusNode: _confirmFocus,
                obscureText: true,
                isPasswordVisible: _isConfirmVisible,
                onToggleVisibility: () =>
                    setState(() => _isConfirmVisible = !_isConfirmVisible),
                errorText: _confirmError,
                onChanged: _onConfirmChanged,
                onSubmitted: (_) => _handleSignUp(),
                enabled: !_isLoading,
                prefixIcon: const Icon(Icons.shield_outlined, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Agreement checkboxes
        AgreementCheckboxes(
          agreedToTerms: _agreedToTerms,
          agreedToPrivacy: _agreedToPrivacy,
          onTermsChanged: (v) => setState(() => _agreedToTerms = v),
          onPrivacyChanged: (v) => setState(() => _agreedToPrivacy = v),
          onTermsTapped: () => TermsConditionsSheet.show(context),
          onPrivacyTapped: () => DataPrivacySheet.show(context),
        ),

        const SizedBox(height: 24),

        // Submit button
        _submitButton(),

        const SizedBox(height: 16),

        // Trust message
        const _TrustMessage(),

        const SizedBox(height: 20),

        // Sign in link
        _SignInRow(onSignIn: widget.onSignIn, isLoading: _isLoading),
      ],
    );

    if (widget.isBottomSheet) {
      return FadeSlideTransition(
        animation: widget.entrance,
        interval: const Interval(0.35, 0.65, curve: Curves.easeOut),
        slideY: 0,
        child: columnContent,
      );
    }

    return FadeSlideTransition(
      animation: widget.entrance,
      interval: const Interval(0.30, 0.60, curve: Curves.easeOut),
      slideY: 40,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFDFDFD)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 14),
              blurRadius: 32,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: columnContent,
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardIntro() {
    if (widget.isBottomSheet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Choose how you'd like to sign in.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Credentials',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose how you want to sign in, then create a secure password.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType? keyboardType,
    String? errorText,
    bool obscureText = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    Widget? prefixIcon,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          obscureText: obscureText && !isPasswordVisible,
          enabled: enabled,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: obscureText
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : suffixIcon,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }

  Widget _phonePrefix() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('\u{1F1F5}\u{1F1ED}', style: TextStyle(fontSize: 18)),
          SizedBox(width: 4),
          Text(
            '+63',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController, _glowAnimation]),
        builder: (context, child) => Transform.scale(
          scale: _scaleController.value,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 56,
              minWidth: double.infinity,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: (_isLoading || !_canSubmit)
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF8A60), Color(0xFFFF5C35)],
                      ),
                color: (_isLoading || !_canSubmit)
                    ? const Color(0xFFD1D5DB)
                    : null,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5C35).withValues(
                      alpha: (_isLoading || !_canSubmit)
                          ? 0.0
                          : _glowAnimation.value,
                    ),
                    offset: const Offset(0, 6),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (_isLoading || !_canSubmit) ? null : _handleSignUp,
                  borderRadius: BorderRadius.circular(100),
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Creating account...',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: (_isLoading || !_canSubmit)
                                  ? const Color(0xFF6B7280)
                                  : Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: (_isLoading || !_canSubmit)
                                ? const Color(0xFF6B7280)
                                : Colors.white,
                            size: 22,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Trust Message ---

class _TrustMessage extends StatelessWidget {
  const _TrustMessage();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
        SizedBox(width: 6),
        Text(
          'Your information is encrypted and secure',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

// --- Sign In Row ---

class _SignInRow extends StatelessWidget {
  final VoidCallback onSignIn;
  final bool isLoading;

  const _SignInRow({required this.onSignIn, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF4B5563),
          ),
        ),
        GestureDetector(
          onTap: isLoading ? null : onSignIn,
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryHover,
            ),
          ),
        ),
      ],
    );
  }
}

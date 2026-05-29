import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/data/registration_constants.dart';
import 'package:tander_flutter_v3/features/auth/data/registration_method.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/agreement_checkboxes.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/agreement_required_dialog.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_error_display.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_success_confirmation.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/availability_suffix_icon.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/method_selector.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/password_requirements_checklist.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/utils/validators.dart';
import 'package:tander_flutter_v3/shared/widgets/data_privacy_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/fade_slide_transition.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart'
    show ValidationMode;
import 'package:tander_flutter_v3/shared/widgets/terms_conditions_sheet.dart';

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

class _SignUpFormCardState extends ConsumerState<SignUpFormCard> {
  final _contactCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _contactFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  RegistrationMethod _method = RegistrationMethod.phone;

  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isLoading = false;
  String? _errorMessage;
  NetworkException? _offlineError;

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

  /// Validator for the confirm-password field in onBlurThenLive mode.
  ///
  /// Returns null while empty (don't yell before the user has typed), and
  /// only flags a mismatch when the field has content. Submit-time
  /// validation still runs via [_validate] and sets [_confirmError]; that
  /// path is harmless here since the validator drives display in this mode.
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value != _passwordCtrl.text) return 'Passwords do not match';
    return null;
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
        _contactError = 'Enter your phone number';
        isValid = false;
      } else if (digits.length != RegistrationConstants.phoneDigitLength) {
        _contactError = 'Please enter all 10 digits';
        isValid = false;
      } else if (!digits.startsWith('9')) {
        _contactError = 'Philippine numbers start with 9';
        isValid = false;
      } else if (_phoneAvailability == AvailabilityStatus.taken) {
        _contactError =
            'This phone number is already registered. Sign in to complete your profile.';
        isValid = false;
      }
    } else {
      final emailError = Validators.email(contact);
      if (emailError != null) {
        _contactError = emailError;
        isValid = false;
      } else if (_emailAvailability == AvailabilityStatus.taken) {
        _contactError =
            'This email is already registered. Sign in to complete your profile.';
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
      _offlineError = null;
    });

    try {
      final contact = _contactCtrl.text.trim();
      final password = _passwordCtrl.text;

      // Read auditId from secure storage
      final auditIdResult = await ref.read(secureStorageProvider).readAuditId();
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
          unawaited(
            context.push(
              AppRoutes.otpVerification,
              extra: {
                'email': isPhone ? '' : normalizedContact,
                'phone': isPhone ? normalizedContact : '',
                'type': 'REGISTRATION',
              },
            ),
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

      await sendResult.when(
        success: (_) async {
          setState(() => _isLoading = false);
          await AuthSuccessConfirmation.show(context, 'Account created!');
          if (!mounted) return;
          unawaited(
            context.push(
              AppRoutes.otpVerification,
              extra: {
                'email': isPhone ? '' : normalizedContact,
                'phone': isPhone ? normalizedContact : '',
                'type': 'REGISTRATION',
              },
            ),
          );
        },
        failure: (exception) async {
          if (exception is NetworkException) {
            setState(() {
              _isLoading = false;
              _offlineError = exception;
            });
            return;
          }
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

  /// Scrollable section of the form (everything except checkboxes + button).
  /// Used by the phone (isBottomSheet) layout as the inner SCV child.
  Widget _buildScrollableContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Offline-retry banner (sticky — see network_exception_handler.dart
        // policy comment). Rendered above the generic error banner.
        if (_offlineError != null) ...[
          AuthErrorDisplay.banner(
            message: _offlineError!.userMessage,
            autoDismiss: false,
            onRetry: _handleSignUp,
            onDismiss: () => setState(() => _offlineError = null),
          ),
          const SizedBox(height: 16),
        ],
        // Banner tier: see AuthErrorDisplay docs for tier policy.
        if (_errorMessage != null) ...[
          AuthErrorDisplay.banner(
            message: _errorMessage!,
            onDismiss: () => setState(() => _errorMessage = null),
          ),
          const SizedBox(height: 16),
        ],

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
              const SizedBox(height: 20),
              if (_method == RegistrationMethod.phone)
                _buildTextField(
                  label: 'Mobile Number',
                  hint: '912 345 6789',
                  controller: _contactCtrl,
                  focusNode: _contactFocus,
                  keyboardType: TextInputType.phone,
                  validationMode: ValidationMode.onBlurThenLive,
                  validator: (_) => _contactError,
                  onChanged: _onPhoneChanged,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  enabled: !_isLoading,
                  prefixIcon: _phonePrefix(),
                  suffixIcon: AvailabilitySuffixIcon(
                    status: _phoneAvailability,
                  ),
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
                  validationMode: ValidationMode.onBlurThenLive,
                  validator: (_) => _contactError,
                  onChanged: _onEmailChanged,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  enabled: !_isLoading,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF9CA3AF),
                  ),
                  suffixIcon: AvailabilitySuffixIcon(
                    status: _emailAvailability,
                  ),
                ),
              const SizedBox(height: 20),
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
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 20),
              if (_showPasswordChecklist) ...[
                PasswordRequirementsChecklist(
                  password: _passwordCtrl.text,
                  confirmPassword: _confirmCtrl.text.isNotEmpty
                      ? _confirmCtrl.text
                      : null,
                ),
                const SizedBox(height: 20),
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
                validationMode: ValidationMode.onBlurThenLive,
                validator: _validateConfirmPassword,
                onChanged: _onConfirmChanged,
                onSubmitted: (_) => _handleSignUp(),
                enabled: !_isLoading,
                prefixIcon: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Trust message
        const _TrustMessage(),

        const SizedBox(height: 20),

        // Sign in link
        _SignInRow(onSignIn: widget.onSignIn, isLoading: _isLoading),
      ],
    );
  }

  /// Sticky footer for phone (isBottomSheet) layout: pinned
  /// AgreementCheckboxes + Create Account button so the CTA is always
  /// reachable above the keyboard.
  Widget _buildStickyFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AgreementCheckboxes(
          agreedToTerms: _agreedToTerms,
          agreedToPrivacy: _agreedToPrivacy,
          onTermsChanged: (v) => setState(() => _agreedToTerms = v),
          onPrivacyChanged: (v) => setState(() => _agreedToPrivacy = v),
          onTermsTapped: () => TermsConditionsSheet.show(context),
          onPrivacyTapped: () => DataPrivacySheet.show(context),
        ),
        const SizedBox(height: 16),
        TanderButton(
          label: _isLoading ? 'Creating account...' : 'Create Account',
          onPressed: (!_isLoading && _canSubmit) ? _handleSignUp : null,
          variant: TanderButtonVariant.primary,
          size: TanderButtonSize.normal,
          isLoading: _isLoading,
          isDisabled: !_canSubmit,
          icon: _isLoading ? null : Icons.arrow_forward_rounded,
          iconPosition: IconPosition.trailing,
        ),
      ],
    );
  }

  /// Legacy single-Column body used by tablet/landscape (non-bottom-sheet)
  /// layouts. Phone layout uses Expanded(SCV) + sticky footer instead.
  Widget _buildLegacyColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScrollableContent(),
        const SizedBox(height: 20),
        AgreementCheckboxes(
          agreedToTerms: _agreedToTerms,
          agreedToPrivacy: _agreedToPrivacy,
          onTermsChanged: (v) => setState(() => _agreedToTerms = v),
          onPrivacyChanged: (v) => setState(() => _agreedToPrivacy = v),
          onTermsTapped: () => TermsConditionsSheet.show(context),
          onPrivacyTapped: () => DataPrivacySheet.show(context),
        ),
        const SizedBox(height: 24),
        TanderButton(
          label: _isLoading ? 'Creating account...' : 'Create Account',
          onPressed: (!_isLoading && _canSubmit) ? _handleSignUp : null,
          variant: TanderButtonVariant.primary,
          size: TanderButtonSize.normal,
          isLoading: _isLoading,
          isDisabled: !_canSubmit,
          icon: _isLoading ? null : Icons.arrow_forward_rounded,
          iconPosition: IconPosition.trailing,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isBottomSheet) {
      // Phone layout: Expanded(SCV) + sticky checkboxes + button.
      // The screen-level scroll has been removed in sign_up_screen so this
      // form card owns its scroll behavior.
      final cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFFFFFBF8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Orange accent bar at top (matching login)
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF07040), Color(0xFFE86035)],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: _buildScrollableContent(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: _buildStickyFooter(),
              ),
            ],
          ),
        ),
      );

      return FadeSlideTransition(
        animation: widget.entrance,
        interval: const Interval(0.35, 0.65, curve: Curves.easeOut),
        slideY: 0,
        child: cardContent,
      );
    }

    // Tablet/landscape: legacy mainAxisSize.min Column inside parchment panel's
    // own scroll. Unchanged behavior.
    final cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF07040), Color(0xFFE86035)],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(color: Color(0xFFFFFBF8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _buildLegacyColumn(),
            ),
          ),
        ],
      ),
    );

    return FadeSlideTransition(
      animation: widget.entrance,
      interval: const Interval(0.30, 0.60, curve: Curves.easeOut),
      slideY: 40,
      child: cardContent,
    );
  }

  Widget _cardIntro() {
    // Simple heading matching login screen style
    return const Text(
      'Create Account',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827),
        letterSpacing: -0.5,
        height: 1.1,
      ),
      textAlign: TextAlign.center,
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
    ValidationMode validationMode = ValidationMode.legacy,
    FormFieldValidator<String>? validator,
  }) {
    final isOnBlur = validationMode == ValidationMode.onBlurThenLive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
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
          // onBlurThenLive: native onUnfocus autovalidation drives display.
          autovalidateMode: isOnBlur ? AutovalidateMode.onUnfocus : null,
          validator: isOnBlur ? validator : null,
          style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            // In onBlurThenLive mode, errorText prop is IGNORED — errors flow
            // through the validator's return value (rendered natively).
            errorText: isOnBlur ? null : errorText,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.danger),
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
        Semantics(
          button: true,
          label: 'Sign in',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isLoading ? null : onSignIn,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              child: const Center(
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondaryHover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

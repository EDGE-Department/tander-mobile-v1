import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/auth/domain/age_eligibility.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_error_display.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_success_confirmation.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_trust_footer.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/dob_help_sheet.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/profile_form_fields.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_confirm_dialog.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Onboarding step 3 of 5 — collects first name, last name, date of birth,
/// gender, and bio.
///
/// Matches sign-up/OTP design: gradient bg + constellation header + white sheet.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _scrollController = ScrollController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isSubmitting = false;
  bool _dobLocked = false;
  String? _apiErrorMessage;
  NetworkException? _offlineError;
  bool _showScrollIndicator = true;

  // Autosave state — draft persists across back-press / app-kill so seniors
  // don't lose typed names. Scoped per-user; 7-day TTL. Draft-wins precedence
  // is per-field via empty-check inside `_fetchIdentityData`, not via a flag.
  Timer? _draftSaveTimer;
  static const Duration _draftTtl = Duration(days: 7);

  // OCR empty-state hint flags — set in _fetchIdentityData's finally block.
  bool _ocrFetchAttempted = false;
  bool _ocrPrefilledAnything = false;

  String? get _draftKey {
    final userId = ref.read(sessionManagerProvider).session?.userId;
    return userId == null ? null : 'profile_setup_draft_$userId';
  }

  @override
  void initState() {
    super.initState();
    // Load draft FIRST so OCR fills only empty fields (draft-wins per-field).
    _loadDraft().then((_) => _fetchIdentityData());
    _scrollController.addListener(_onScroll);
    _firstNameController.addListener(_scheduleDraftSave);
    _middleNameController.addListener(_scheduleDraftSave);
    _lastNameController.addListener(_scheduleDraftSave);
    _bioController.addListener(_scheduleDraftSave);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final shouldShow = maxScroll > 20 && currentScroll < maxScroll - 20;
    if (shouldShow != _showScrollIndicator) {
      setState(() => _showScrollIndicator = shouldShow);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    _firstNameController.removeListener(_scheduleDraftSave);
    _middleNameController.removeListener(_scheduleDraftSave);
    _lastNameController.removeListener(_scheduleDraftSave);
    _bioController.removeListener(_scheduleDraftSave);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -- Autosave -------------------------------------------------------------

  Future<void> _loadDraft() async {
    final key = _draftKey;
    if (key == null) return;
    final result = ref.read(localStorageProvider).getString(key);
    final json = result is Success<String?> ? result.value : null;
    if (json == null || json.isEmpty) return;
    try {
      final draft = jsonDecode(json) as Map<String, dynamic>;
      final savedAtStr = draft['savedAt'] as String?;
      final savedAt = savedAtStr == null ? null : DateTime.tryParse(savedAtStr);
      if (savedAt == null || DateTime.now().difference(savedAt) > _draftTtl) {
        // Stale or invalid — discard
        await ref.read(localStorageProvider).remove(key);
        return;
      }
      if (!mounted) return;
      _firstNameController.text = (draft['firstName'] as String?) ?? '';
      _middleNameController.text = (draft['middleName'] as String?) ?? '';
      _lastNameController.text = (draft['lastName'] as String?) ?? '';
      _bioController.text = (draft['bio'] as String?) ?? '';
      final dobStr = draft['dateOfBirth'] as String?;
      if (dobStr != null) {
        _selectedBirthDate = DateTime.tryParse(dobStr);
      }
      _selectedGender = draft['gender'] as String?;
      if (mounted) setState(() {});
    } catch (e, st) {
      AppLogger.warning(
        'Profile draft parse failed; discarding',
        operation: 'ProfileSetupScreen._loadDraft',
        error: e,
        stackTrace: st,
      );
      await ref.read(localStorageProvider).remove(key);
    }
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 600), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final key = _draftKey;
    if (key == null) return;
    final draft = <String, dynamic>{
      'firstName': _firstNameController.text,
      'middleName': _middleNameController.text,
      'lastName': _lastNameController.text,
      'dateOfBirth': _selectedBirthDate?.toIso8601String(),
      'gender': _selectedGender,
      'bio': _bioController.text,
      'savedAt': DateTime.now().toIso8601String(),
    };
    final hasContent =
        (draft['firstName'] as String).isNotEmpty ||
        (draft['middleName'] as String).isNotEmpty ||
        (draft['lastName'] as String).isNotEmpty ||
        (draft['bio'] as String).isNotEmpty ||
        draft['dateOfBirth'] != null ||
        draft['gender'] != null;
    if (!hasContent) {
      // Nothing worth saving — clear any stale draft instead
      await ref.read(localStorageProvider).remove(key);
      return;
    }
    final result = await ref
        .read(localStorageProvider)
        .saveString(key, jsonEncode(draft));
    if (result is Failure) {
      AppLogger.warning(
        'Profile draft save failed (non-fatal)',
        operation: 'ProfileSetupScreen._saveDraft',
        error: result.exception,
      );
    }
  }

  Future<void> _clearDraft() async {
    final key = _draftKey;
    if (key == null) return;
    await ref.read(localStorageProvider).remove(key);
  }

  Future<void> _fetchIdentityData() async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final response = await dioClient.get<Map<String, Object?>>(
        ApiEndpoints.identityData,
      );
      final data = response.data?['data'];
      if (data is Map<String, Object?> && mounted) {
        final firstName = data['firstName'] as String?;
        final middleName = data['middleName'] as String?;
        final lastName = data['lastName'] as String?;
        final dob = data['dateOfBirth'] as String?;
        final gender = data['gender'] as String?;

        // Draft-wins per-field: OCR fills only EMPTY fields so user's typed
        // values aren't blown away if they navigated back to a draft session.
        if (firstName != null &&
            firstName.isNotEmpty &&
            _firstNameController.text.isEmpty) {
          _firstNameController.text = _cleanName(firstName);
        }
        if (middleName != null &&
            middleName.isNotEmpty &&
            _middleNameController.text.isEmpty) {
          _middleNameController.text = _cleanName(middleName);
        }
        if (lastName != null &&
            lastName.isNotEmpty &&
            _lastNameController.text.isEmpty) {
          _lastNameController.text = _cleanName(lastName);
        }
        if (dob != null && dob.isNotEmpty && _selectedBirthDate == null) {
          final parsed = DateTime.tryParse(dob);
          if (parsed != null) {
            _selectedBirthDate = parsed;
            _dobLocked = true;
          }
        }
        if (gender != null && gender.isNotEmpty && _selectedGender == null) {
          final normalizedGender = gender.trim().toUpperCase();
          if (normalizedGender == 'M' || normalizedGender == 'MALE') {
            _selectedGender = 'Male';
          } else if (normalizedGender == 'F' || normalizedGender == 'FEMALE') {
            _selectedGender = 'Female';
          }
        }
        setState(() {});
      }
    } catch (_) {
      // Non-fatal — user can still fill manually
    } finally {
      if (mounted) {
        final anyFilled =
            _firstNameController.text.isNotEmpty ||
            _middleNameController.text.isNotEmpty ||
            _lastNameController.text.isNotEmpty ||
            _selectedBirthDate != null ||
            _selectedGender != null;
        setState(() {
          _ocrFetchAttempted = true;
          _ocrPrefilledAnything = anyFilled;
        });
      }
    }
  }

  String _cleanName(String input) {
    // Strip trailing punctuation (commas, periods) common in OCR
    final cleaned = input
        .replaceAll(RegExp(r'[,.\s]+$'), '')
        .replaceAll(RegExp(r'^[,.\s]+'), '')
        .trim();
    return cleaned
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  // -- Validation -----------------------------------------------------------

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please share your first name';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please share your last name';
    }
    return null;
  }

  // -- Submit ---------------------------------------------------------------

  Future<void> _submitForm() async {
    // Re-entrancy guard. _isSubmitting is flipped synchronously below — before
    // any await — so a second tap during the manual-DOB age-config fetch bails
    // here instead of firing a concurrent submit (double PUT + double navigate).
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _apiErrorMessage = null;
      _offlineError = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = false);
      return;
    }
    if (_selectedBirthDate == null) {
      setState(() {
        _isSubmitting = false;
        _apiErrorMessage = 'Please select your date of birth.';
      });
      return;
    }

    try {
      // Manual-DOB age gate. A locked DOB was prefilled from the verified ID,
      // which already cleared the backend's mandatory ID age-gate, so it is not
      // re-checked here. Manually-typed DOBs are gated against the backend's
      // advertised minimum (minimumAgeProvider). When that minimum is unknown
      // (config fetch failed → null), isBirthDateBelowMinimum FAILS OPEN: the
      // backend ID gate is the real enforcer, so a restrictive client fallback
      // would only re-trap eligible users — the original bug. The await lives
      // inside the try so the finally always clears _isSubmitting even if it
      // ever threw (today it cannot — the provider is Result-wrapped).
      if (!_dobLocked) {
        final minAge = await ref.read(minimumAgeProvider.future);
        if (!mounted) return;
        if (isBirthDateBelowMinimum(
          birthDate: _selectedBirthDate!,
          minimumAge: minAge,
          asOf: DateTime.now(),
        )) {
          // Reachable only when minAge is non-null (the gate fails open and
          // returns false for null), so the interpolated value is a real number.
          setState(
            () => _apiErrorMessage =
                'You need to be $minAge or older to join Tander. '
                "Come back when you're eligible!",
          );
          return;
        }
      }

      final dioClient = ref.read(dioClientProvider);
      final middleName = _middleNameController.text.trim();
      final requestDto = UpdateProfileRequestDto(
        firstName: _firstNameController.text.trim(),
        middleName: middleName.isNotEmpty ? middleName : null,
        lastName: _lastNameController.text.trim(),
        birthDate: DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
        gender: _selectedGender,
        bio: _bioController.text.trim(),
      );

      await dioClient.put<Map<String, Object?>>(
        ApiEndpoints.updateProfile,
        data: requestDto.toJson(),
        queryParameters: {'markAsComplete': 'true'},
      );

      await ref.read(authNotifierProvider.notifier).refreshSession();
      // Profile saved successfully — clear draft so a future return to this
      // screen (after re-registration or other flows) starts fresh.
      await _clearDraft();
      if (!mounted) return;
      await AuthSuccessConfirmation.show(context, 'Profile saved!');
      if (mounted) context.go(AppRoutes.photoSetup);
    } on DioException catch (error, stackTrace) {
      // Catch ordering policy — see network_exception_handler.dart.
      // DioException only reaches here for raw Dio errors that escape
      // DioClient's mapping (e.g. session-expired sentinel). 401 is checked
      // first and short-circuits to login.
      AppLogger.error(
        'Profile setup submission failed',
        operation: 'ProfileSetupScreen._submitForm',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        final isSessionExpired =
            error.message?.contains('Session expired') == true ||
            error.response?.statusCode == 401;

        if (isSessionExpired) {
          TanderToastOverlay.show(
            context,
            const TanderToastData(
              message: 'Session expired. Please sign in again.',
              variant: TanderToastVariant.error,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.go(AppRoutes.login);
        } else {
          TanderToastOverlay.show(
            context,
            const TanderToastData(
              message: 'Something went wrong. Please try again.',
              variant: TanderToastVariant.error,
            ),
          );
        }
      }
    } on NetworkException catch (error, stackTrace) {
      AppLogger.error(
        'Profile setup submission failed (offline)',
        operation: 'ProfileSetupScreen._submitForm',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _offlineError = error);
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Profile setup submission failed',
        operation: 'ProfileSetupScreen._submitForm',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        TanderToastOverlay.show(
          context,
          const TanderToastData(
            message: 'Something went wrong. Please try again.',
            variant: TanderToastVariant.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Sign out from onboarding — the only navigation that escapes this screen.
  /// While the phase is pendingProfileSetup, context.go(login) bounces straight
  /// back here (see app_router.dart _redirectForOnboarding), so a real sign-out
  /// (-> AuthUnauthenticated) is the sole exit. Non-destructive: the account
  /// persists server-side and the local draft is saved, so a later sign-in
  /// resumes this step.
  Future<void> _confirmSignOut() async {
    final didConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Sign out?',
      message:
          'You can sign back in anytime to finish setting up your profile — '
          'your progress is saved on this device.',
      confirmLabel: 'Sign out',
    );
    if (didConfirm != true) return;
    unawaited(ref.read(authNotifierProvider.notifier).signOut());
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = resolveHeaderHeight(screenHeight);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF20BF68),
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
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: _buildWhiteSheet(),
                  ),
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
          // Ghost "Tander" wordmark - matches login screen exactly
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

          // Step badge — top-right like online count
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              left: false,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: StepBadgeEntry(
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
                        'Step 3 of 5',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ),
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
          ),

          // Sign-out escape — top-left, mirrors the step badge. Placed LAST in
          // the Stack so it paints above the (non-interactive) brand content and
          // is unambiguously tappable. This is the only way out of onboarding:
          // context.go(login) bounces back here while the phase is
          // pendingProfileSetup (app_router.dart _redirectForOnboarding).
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: TextButton.icon(
                  onPressed: _isSubmitting ? null : _confirmSignOut,
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Sign out',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, AppSpacing.touchMinimum),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteSheet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFFFFFBF8)),
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
                  // Orange accent bar at top - matches login form card
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF07040), Color(0xFFE86035)],
                      ),
                    ),
                  ),
                  // Scrollable form content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: _buildFormContent(),
                    ),
                  ),
                  // Trust signal — small lock + reassurance text
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: AuthTrustFooter(),
                  ),
                  // Sticky Continue button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: TanderButton(
                      label: _isSubmitting ? 'Saving...' : 'Continue',
                      onPressed: _isSubmitting ? null : _submitForm,
                      variant: TanderButtonVariant.primary,
                      size: TanderButtonSize.normal,
                      isLoading: _isSubmitting,
                      icon: _isSubmitting ? null : Icons.arrow_forward_rounded,
                      iconPosition: IconPosition.trailing,
                    ),
                  ),
                ],
              ),
              // Floating scroll-to-bottom button on right side
              Positioned(
                right: 12,
                bottom: 100,
                child: AnimatedOpacity(
                  opacity: _showScrollIndicator ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedScale(
                    scale: _showScrollIndicator ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE67E22,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tell Us About You',
          textAlign: TextAlign.center,
          style: AppTypography.displayLg.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your bio helps others learn about you',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        if (_ocrFetchAttempted && !_ocrPrefilledAnything) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "Please type your details below — we couldn't auto-fill them from your ID this time.",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (_offlineError != null) ...[
          // Offline-retry banner — see network_exception_handler.dart policy.
          AuthErrorDisplay.banner(
            message: _offlineError!.userMessage,
            autoDismiss: false,
            onRetry: _submitForm,
            onDismiss: () => setState(() => _offlineError = null),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_apiErrorMessage != null) ...[
          // Banner tier: see AuthErrorDisplay docs for tier policy.
          AuthErrorDisplay.banner(
            message: _apiErrorMessage!,
            onDismiss: () => setState(() => _apiErrorMessage = null),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameFields(),
              const SizedBox(height: AppSpacing.md),
              BirthDatePickerField(
                selectedDate: _selectedBirthDate,
                locked: _dobLocked,
                // Fail open: floor at 18 (permissive) when the backend minimum
                // is unknown/loading, so an eligible user can always pick their
                // real birthday. A restrictive fallback would relocate the trap
                // to the picker. (Picker is disabled anyway when _dobLocked.)
                minimumAge: pickerAgeFloor(
                  ref.watch(minimumAgeProvider).valueOrNull,
                ),
                onHelpTapped: () => DobHelpSheet.show(context),
                onPicked: _dobLocked
                    ? null
                    : (date) {
                        setState(() {
                          _selectedBirthDate = date;
                          _apiErrorMessage = null;
                        });
                        _scheduleDraftSave();
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              GenderDropdownField(
                selectedGender: _selectedGender,
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                  _scheduleDraftSave();
                },
              ),
              const SizedBox(height: AppSpacing.md),
              BioTextField(
                controller: _bioController,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TanderTextField(
                label: 'First Name',
                hint: 'Juan',
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                validator: _validateFirstName,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TanderTextField(
                label: 'Last Name',
                hint: 'Dela Cruz',
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                validator: _validateLastName,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TanderTextField(
          label: 'Middle Name (optional)',
          hint: 'Santos',
          controller: _middleNameController,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/profile_form_fields.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Onboarding step 3 of 4 — collects first name, last name, date of birth,
/// gender, and bio.
///
/// Matches sign-up/OTP design: gradient bg + constellation header + white sheet.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
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
  bool _showScrollIndicator = true;

  @override
  void initState() {
    super.initState();
    _fetchIdentityData();
    _scrollController.addListener(_onScroll);
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
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _scrollController.dispose();
    super.dispose();
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

        if (firstName != null && firstName.isNotEmpty) {
          _firstNameController.text = _cleanName(firstName);
        }
        if (middleName != null && middleName.isNotEmpty) {
          _middleNameController.text = _cleanName(middleName);
        }
        if (lastName != null && lastName.isNotEmpty) {
          _lastNameController.text = _cleanName(lastName);
        }
        if (dob != null && dob.isNotEmpty) {
          final parsed = DateTime.tryParse(dob);
          if (parsed != null) {
            _selectedBirthDate = parsed;
            _dobLocked = true;
          }
        }
        if (gender != null && gender.isNotEmpty) {
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
      if (mounted) setState(() {});
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
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  // -- Validation -----------------------------------------------------------

  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) return 'First name is required';
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Last name is required';
    return null;
  }

  bool get _isBirthDateValid {
    if (_selectedBirthDate == null) return false;
    final today = DateTime.now();
    final age = today.year - _selectedBirthDate!.year;
    final hasBirthdayPassed = today.month > _selectedBirthDate!.month ||
        (today.month == _selectedBirthDate!.month &&
            today.day >= _selectedBirthDate!.day);
    return (hasBirthdayPassed ? age : age - 1) >= 18;
  }

  // -- Submit ---------------------------------------------------------------

  Future<void> _submitForm() async {
    setState(() => _apiErrorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedBirthDate == null) {
      setState(() => _apiErrorMessage = 'Please select your date of birth.');
      return;
    }
    if (!_isBirthDateValid) {
      setState(() => _apiErrorMessage = 'You must be at least 18 years old.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
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
      if (mounted) context.go(AppRoutes.photoSetup);
    } on DioException catch (error, stackTrace) {
      AppLogger.error(
        'Profile setup submission failed',
        operation: 'ProfileSetupScreen._submitForm',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        final isSessionExpired = error.message?.contains('Session expired') == true ||
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
                child: Container(
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
                      'Step 3 of 4',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
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
                      style: AppTypography.brandWordmark(
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
                          Shadow(
                            blurRadius: 50,
                            color: Color(0x47FFA050),
                          ),
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


  Widget _buildWhiteSheet() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF8),
          ),
          child: Stack(
            children: [
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
                  // Sticky Continue button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: _ContinueButton(
                      isLoading: _isSubmitting,
                      onPressed: _submitForm,
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
                              color: const Color(0xFFE67E22).withValues(alpha: 0.3),
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
          'Help others get to know the real you',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_apiErrorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _apiErrorMessage!,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
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
                onPicked: _dobLocked
                    ? null
                    : (date) => setState(() {
                          _selectedBirthDate = date;
                          _apiErrorMessage = null;
                        }),
              ),
              const SizedBox(height: AppSpacing.md),
              GenderDropdownField(
                selectedGender: _selectedGender,
                onChanged: (value) =>
                    setState(() => _selectedGender = value),
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

/// Orange gradient continue button matching login submit button style.
class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isLoading;

    return Opacity(
      opacity: widget.isLoading ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: isInteractive ? widget.onPressed : null,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE67E22), Color(0xFFD35400)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59E67E22),
                blurRadius: 40,
                offset: Offset(0, 20),
                spreadRadius: -12,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (_, __) {
                      final translateX =
                          (_shimmerController.value * 3.0 - 1.0);
                      return FractionallySizedBox(
                        widthFactor: 1.0,
                        child: Transform.translate(
                          offset: Offset(
                            translateX * MediaQuery.sizeOf(context).width,
                            0,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0x38FFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              widget.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SAVING...',
                          style: AppTypography.body.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.12 * 16,
                            height: 1.0,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CONTINUE',
                          style: AppTypography.body.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.12 * 16,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 24,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

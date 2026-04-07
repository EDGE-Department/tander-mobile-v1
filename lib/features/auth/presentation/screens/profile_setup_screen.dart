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
import 'package:tander_flutter_v3/features/auth/presentation/widgets/registration_step_dots.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
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

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isSubmitting = false;
  bool _isLoadingIdentity = true;
  bool _dobLocked = false;
  String? _apiErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchIdentityData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
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
          _selectedGender = _cleanName(gender);
        }
        setState(() {});
      }
    } catch (_) {
      // Non-fatal — user can still fill manually
    } finally {
      if (mounted) setState(() => _isLoadingIdentity = false);
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

    return Scaffold(
      backgroundColor: const Color(0xFF20BF68),
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
        const SizedBox(width: 40),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: RegistrationStepDots(currentStep: 3, totalSteps: 4),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: _buildFormContent(),
              ),
            ),
          ],
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
          style: AppTypography.h1.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Help others get to know the real you',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              TanderButton(
                label: 'Continue',
                onPressed: _isSubmitting ? null : _submitForm,
                isLoading: _isSubmitting,
                icon: Icons.arrow_forward_rounded,
                iconPosition: IconPosition.trailing,
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

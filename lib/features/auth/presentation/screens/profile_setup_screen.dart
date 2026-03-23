import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/onboarding_chrome.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/profile_form_fields.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Onboarding step 1 of 3 — collects first name, last name, date of birth,
/// gender, and bio.
///
/// Matches the web profile-setup-page.tsx mobile layout: warm gradient bg,
/// step badge, heading, form card with fields and continue button.
/// Submits via PUT /user/profile, then navigates to [AppRoutes.photoSetup].
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  bool _isSubmitting = false;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
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
      final requestDto = UpdateProfileRequestDto(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthDate: DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
        gender: _selectedGender,
        bio: _bioController.text.trim(),
      );

      await dioClient.put<Map<String, Object?>>(
        ApiEndpoints.updateProfile,
        data: requestDto.toJson(),
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
    return Scaffold(
      body: DecoratedBox(
        decoration: onboardingGradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnboardingStepBadge(currentStep: 1),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeading(),
                    const SizedBox(height: AppSpacing.lg),
                    if (_apiErrorMessage != null) ...[
                      OnboardingErrorBanner(message: _apiErrorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildFormCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Tell Us About You',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Help others get to know the real you',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.warmLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNameFields(),
              const SizedBox(height: AppSpacing.md),
              BirthDatePickerField(
                selectedDate: _selectedBirthDate,
                onPicked: (date) => setState(() {
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
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
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
    );
  }
}

/// Full profile editing form screen.
///
/// Pre-populates all fields from the current profile and submits changes
/// via [MyProfileNotifier.updateProfile]. Uses [ConsumerStatefulWidget]
/// to own [TextEditingController] lifecycle.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/notifiers/my_profile_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/states/profile_state.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_edit_form_fields.dart';
import 'package:tander_flutter_v3/shared/widgets/section_label.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Maximum bio length.
const int _maxBioLength = 300;

/// Profile editing screen with form fields pre-populated from current profile.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _nickNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _selectedCivilStatus;
  String? _selectedReligion;
  int? _selectedChildrenCount;
  List<String> _selectedInterests = [];
  List<String> _selectedLookingFor = [];
  List<String> _selectedLanguages = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _nickNameController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _countryController = TextEditingController();

    _bioController.addListener(_onBioChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFromProfile();
    });
  }

  void _onBioChanged() {
    setState(() {});
  }

  void _populateFromProfile() {
    final profileState = ref.read(myProfileNotifierProvider);
    if (profileState is! ProfileLoaded) return;

    final profile = profileState.profile;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName ?? '';
    _nickNameController.text = profile.nickName ?? '';
    _bioController.text = profile.bio ?? '';
    _cityController.text = profile.city ?? '';
    _countryController.text = profile.country ?? '';

    setState(() {
      _selectedGender = profile.gender;
      _selectedDateOfBirth = profile.dateOfBirth;
      _selectedCivilStatus = profile.civilStatus;
      _selectedReligion = profile.religion;
      _selectedChildrenCount = profile.numberOfChildren;
      _selectedInterests = List<String>.from(profile.interests);
      _selectedLookingFor = List<String>.from(profile.lookingFor);
      _selectedLanguages = List<String>.from(profile.languages);
    });
  }

  @override
  void dispose() {
    _bioController.removeListener(_onBioChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nickNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final request = UpdateProfileRequestDto(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      nickName: _nickNameController.text.trim(),
      bio: _bioController.text.trim(),
      city: _cityController.text.trim(),
      country: _countryController.text.trim(),
      gender: _selectedGender,
      birthDate: _selectedDateOfBirth?.toIso8601String().split('T').first,
      civilStatus: _selectedCivilStatus,
      religion: _selectedReligion,
      numberOfChildren: _selectedChildrenCount,
      interests: jsonEncode(_selectedInterests),
      lookingFor: jsonEncode(_selectedLookingFor),
      languages: jsonEncode(_selectedLanguages),
    );

    final didSucceed =
        await ref.read(myProfileNotifierProvider.notifier).updateProfile(request);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (didSucceed) {
      TanderToastOverlay.show(
        context,
        const TanderToastData(
          message: 'Profile updated successfully.',
          variant: TanderToastVariant.success,
        ),
      );
      context.pop();
    } else {
      TanderToastOverlay.show(
        context,
        const TanderToastData(
          message: 'Failed to save changes. Please try again.',
          variant: TanderToastVariant.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bioLength = _bioController.text.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        title: Text('Edit Profile', style: AppTypography.h3),
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.arrowLeft, size: 22),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _SaveButton(
              isSaving: _isSaving,
              onPressed: _handleSave,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(label: 'Basic information'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TanderTextField(
                      label: 'First name',
                      controller: _firstNameController,
                      validator: _requiredValidator,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TanderTextField(
                      label: 'Last name',
                      controller: _lastNameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TanderTextField(
                label: 'Nickname',
                controller: _nickNameController,
                hint: 'What friends call you',
              ),
              const SizedBox(height: AppSpacing.sm),
              _BioField(
                controller: _bioController,
                bioLength: bioLength,
              ),
              const SizedBox(height: AppSpacing.lg),

              SectionLabel(label: 'Personal details'),
              const SizedBox(height: AppSpacing.sm),
              DateOfBirthPicker(selectedDate: _selectedDateOfBirth, onDateSelected: (date) => setState(() => _selectedDateOfBirth = date)),
              const SizedBox(height: AppSpacing.sm),
              GenderDropdown(selectedGender: _selectedGender, onChanged: (gender) => setState(() => _selectedGender = gender)),
              const SizedBox(height: AppSpacing.sm),
              CivilStatusDropdown(selectedStatus: _selectedCivilStatus, onChanged: (status) => setState(() => _selectedCivilStatus = status)),
              const SizedBox(height: AppSpacing.sm),
              ReligionDropdown(selectedReligion: _selectedReligion, onChanged: (religion) => setState(() => _selectedReligion = religion)),
              const SizedBox(height: AppSpacing.sm),
              ChildrenCountDropdown(selectedCount: _selectedChildrenCount, onChanged: (count) => setState(() => _selectedChildrenCount = count)),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel(label: 'Location'),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: TanderTextField(label: 'City', controller: _cityController, hint: 'e.g. Manila')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TanderTextField(label: 'Country', controller: _countryController, hint: 'e.g. Philippines')),
              ]),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel(label: 'Looking for'),
              const SizedBox(height: AppSpacing.sm),
              LookingForSelector(selectedValues: _selectedLookingFor, onChanged: (values) => setState(() => _selectedLookingFor = values)),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel(label: 'Interests'),
              const SizedBox(height: AppSpacing.xs),
              Text('Select up to 8 interests', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.sm),
              InterestSelector(selectedInterests: _selectedInterests, onChanged: (interests) => setState(() => _selectedInterests = interests)),
              const SizedBox(height: AppSpacing.lg),
              const SectionLabel(label: 'Languages'),
              const SizedBox(height: AppSpacing.sm),
              LanguageSelector(selectedLanguages: _selectedLanguages, onChanged: (languages) => setState(() => _selectedLanguages = languages)),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }
}

// ── Private widgets ──────────────────────────────────────────────────────

class _BioField extends StatelessWidget {
  const _BioField({required this.controller, required this.bioLength});
  final TextEditingController controller;
  final int bioLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('About me', style: AppTypography.label),
            Text(
              '$bioLength/$_maxBioLength',
              style: AppTypography.caption.copyWith(
                color: bioLength > 270 ? AppColors.warning : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TanderTextField(
          controller: controller,
          hint: 'Share a little about yourself...',
          maxLines: 4,
          maxLength: _maxBioLength,
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.borderSm,
        ),
        child: isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textInverse),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsBold.check, size: 16,
                      color: AppColors.textInverse),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Save',
                    style: AppTypography.label
                        .copyWith(color: AppColors.textInverse),
                  ),
                ],
              ),
      ),
    );
  }
}

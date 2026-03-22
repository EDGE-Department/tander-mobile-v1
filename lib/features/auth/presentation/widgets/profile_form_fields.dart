import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int maxBioLength = 300;

const List<String> genderOptions = [
  'Male',
  'Female',
  'Non-binary',
  'Prefer not to say',
];

// ---------------------------------------------------------------------------
// Birth date picker field
// ---------------------------------------------------------------------------

/// Elder-friendly tappable field that opens [showDatePicker] with a default
/// year of ~1960 and restricts selection to age 18+.
class BirthDatePickerField extends StatelessWidget {
  const BirthDatePickerField({
    required this.selectedDate,
    required this.onPicked,
    super.key,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onPicked;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = selectedDate ?? DateTime(1960, 1, 1);
    final lastDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: lastDate,
      helpText: 'Select your date of birth',
      fieldHintText: 'MM/DD/YYYY',
      builder: (pickerContext, child) {
        return Theme(
          data: Theme.of(pickerContext).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textInverse,
              surface: AppColors.card,
              onSurface: AppColors.textStrong,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = selectedDate != null
        ? DateFormat('MMMM d, yyyy').format(selectedDate!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () => _pickDate(context),
          child: Container(
            constraints:
                const BoxConstraints(minHeight: AppSpacing.touchComfortable),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    formattedDate ?? 'Select your birth date',
                    style: AppTypography.body.copyWith(
                      color: formattedDate != null
                          ? AppColors.textStrong
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gender dropdown
// ---------------------------------------------------------------------------

class GenderDropdownField extends StatelessWidget {
  const GenderDropdownField({
    required this.selectedGender,
    required this.onChanged,
    super.key,
  });

  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Container(
          constraints:
              const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.borderSm,
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedGender,
              hint: Text(
                'Select gender',
                style:
                    AppTypography.body.copyWith(color: AppColors.textMuted),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted),
              style:
                  AppTypography.body.copyWith(color: AppColors.textStrong),
              dropdownColor: AppColors.card,
              borderRadius: AppRadius.borderSm,
              items: genderOptions
                  .map((gender) => DropdownMenuItem<String>(
                      value: gender, child: Text(gender)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bio text field with character counter
// ---------------------------------------------------------------------------

class BioTextField extends StatelessWidget {
  const BioTextField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Bio ', style: AppTypography.label),
            Text('(optional)',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Stack(
          children: [
            TanderTextField(
              hint:
                  'Share a little about yourself, your hobbies, or what brings you joy...',
              controller: controller,
              maxLines: 4,
              maxLength: maxBioLength,
              onChanged: onChanged,
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.xs,
              child: Text(
                '${controller.text.length}/$maxBioLength',
                style: AppTypography.caption.copyWith(
                  color: controller.text.length > 270
                      ? AppColors.warning
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reusable form field widgets for the profile edit screen.
///
/// Contains dropdowns, multi-select chips, and date pickers.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Constants ───────────────────────────────────────────────────────────

const List<String> genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
const List<String> civilStatusOptions = ['Single', 'Married', 'Widowed', 'Divorced', 'Separated', 'Annulled'];
const List<String> religionOptions = ['Catholic', 'Protestant', 'Iglesia ni Cristo', 'Islam', 'Buddhism', 'Other', 'Prefer not to say'];
const List<String> lookingForOptions = ['FRIENDSHIP', 'COMPANIONSHIP', 'ROMANCE', 'ACTIVITY_BUDDY'];
const Map<String, String> lookingForDisplayLabels = {
  'FRIENDSHIP': 'Friendship', 'COMPANIONSHIP': 'Companionship',
  'ROMANCE': 'Romance', 'ACTIVITY_BUDDY': 'Activity Partner',
};
const List<String> availableInterests = [
  'Reading', 'Cooking', 'Gardening', 'Walking', 'Dancing', 'Music', 'Photography',
  'Travel', 'Fishing', 'Painting', 'Writing', 'Yoga', 'Swimming', 'Volunteering',
  'Chess', 'Card games', 'Birdwatching', 'Crafts', 'Movies', 'Singing',
  'Church', 'Karaoke', 'Basketball', 'Cycling', 'Meditation',
];
const List<String> availableLanguages = [
  'Tagalog', 'English', 'Cebuano', 'Ilocano', 'Hiligaynon', 'Bicolano',
  'Waray', 'Pangasinan', 'Kapampangan', 'Maranao', 'Spanish', 'Mandarin', 'Japanese', 'Korean',
];
const int _maxInterests = 8;

// ── Generic labeled dropdown ────────────────────────────────────────────

class _LabeledDropdown<TValue> extends StatelessWidget {
  const _LabeledDropdown({required this.label, required this.value, required this.items, required this.onChanged, this.hintText = 'Select...', super.key});
  final String label;
  final TValue? value;
  final List<DropdownMenuItem<TValue>> items;
  final ValueChanged<TValue?> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs),
      Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.borderSm, border: Border.all(color: AppColors.border)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DropdownButtonHideUnderline(child: DropdownButton<TValue>(
          value: value, hint: Text(hintText, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          style: AppTypography.body.copyWith(color: AppColors.textStrong),
          dropdownColor: AppColors.card, borderRadius: AppRadius.borderMd,
          items: items, onChanged: onChanged,
        )),
      ),
    ]);
  }
}

// ── Concrete dropdowns ──────────────────────────────────────────────────

class GenderDropdown extends StatelessWidget {
  const GenderDropdown({required this.selectedGender, required this.onChanged, super.key});
  final String? selectedGender;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _LabeledDropdown<String>(
    label: 'Gender', value: genderOptions.contains(selectedGender) ? selectedGender : null,
    hintText: 'Select gender', onChanged: onChanged,
    items: genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
  );
}

class CivilStatusDropdown extends StatelessWidget {
  const CivilStatusDropdown({required this.selectedStatus, required this.onChanged, super.key});
  final String? selectedStatus;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _LabeledDropdown<String>(
    label: 'Civil status', value: civilStatusOptions.contains(selectedStatus) ? selectedStatus : null,
    hintText: 'Select civil status', onChanged: onChanged,
    items: civilStatusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
  );
}

class ReligionDropdown extends StatelessWidget {
  const ReligionDropdown({required this.selectedReligion, required this.onChanged, super.key});
  final String? selectedReligion;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => _LabeledDropdown<String>(
    label: 'Religion', value: religionOptions.contains(selectedReligion) ? selectedReligion : null,
    hintText: 'Select religion', onChanged: onChanged,
    items: religionOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
  );
}

class ChildrenCountDropdown extends StatelessWidget {
  const ChildrenCountDropdown({required this.selectedCount, required this.onChanged, super.key});
  final int? selectedCount;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => _LabeledDropdown<int>(
    label: 'Number of children', value: selectedCount, hintText: 'Select', onChanged: onChanged,
    items: List.generate(11, (i) => DropdownMenuItem(value: i, child: Text(i == 0 ? 'None' : '$i'))),
  );
}

// ── Date of birth picker ────────────────────────────────────────────────

class DateOfBirthPicker extends StatelessWidget {
  const DateOfBirthPicker({required this.selectedDate, required this.onDateSelected, super.key});
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final displayText = selectedDate != null ? DateFormat('MMMM d, yyyy').format(selectedDate!) : 'Select date of birth';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Date of birth', style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs),
      GestureDetector(
        onTap: () => _showDatePicker(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: AppRadius.borderSm, border: Border.all(color: AppColors.border)),
          alignment: Alignment.centerLeft,
          child: Text(displayText, style: AppTypography.body.copyWith(color: selectedDate != null ? AppColors.textStrong : AppColors.textMuted)),
        ),
      ),
    ]);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 65),
      firstDate: DateTime(1920), lastDate: DateTime(now.year - 18),
      helpText: 'SELECT DATE OF BIRTH',
      builder: (pickerContext, child) => Theme(
        data: Theme.of(pickerContext).copyWith(colorScheme: const ColorScheme.light(
          primary: AppColors.primary, onPrimary: AppColors.textInverse,
          surface: AppColors.card, onSurface: AppColors.textStrong,
        )),
        child: child!,
      ),
    );
    if (picked != null) onDateSelected(picked);
  }
}

// ── Multi-select chip selector ──────────────────────────────────────────

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({required this.allOptions, required this.selectedValues, required this.onChanged, required this.displayLabel, this.maxSelections, super.key});
  final List<String> allOptions;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;
  final String Function(String) displayLabel;
  final int? maxSelections;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: allOptions.map((option) {
      final isSelected = selectedValues.contains(option);
      final isDisabled = !isSelected && maxSelections != null && selectedValues.length >= maxSelections!;
      return GestureDetector(
        onTap: isDisabled ? null : () {
          final updated = List<String>.from(selectedValues);
          isSelected ? updated.remove(option) : updated.add(option);
          onChanged(updated);
        },
        child: AnimatedContainer(
          duration: AppDurations.fast, curve: AppCurves.premiumEase,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: AppRadius.borderFull,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: Text(displayLabel(option), style: AppTypography.label.copyWith(color: isSelected ? AppColors.textInverse : AppColors.textBody)),
          ),
        ),
      );
    }).toList());
  }
}

// ── Public chip selectors ───────────────────────────────────────────────

class LookingForSelector extends StatelessWidget {
  const LookingForSelector({required this.selectedValues, required this.onChanged, super.key});
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => _ChipSelector(
    allOptions: lookingForOptions, selectedValues: selectedValues,
    onChanged: onChanged, displayLabel: (option) => lookingForDisplayLabels[option] ?? option,
  );
}

class InterestSelector extends StatelessWidget {
  const InterestSelector({required this.selectedInterests, required this.onChanged, super.key});
  final List<String> selectedInterests;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => _ChipSelector(
    allOptions: availableInterests, selectedValues: selectedInterests,
    onChanged: onChanged, displayLabel: (option) => option, maxSelections: _maxInterests,
  );
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({required this.selectedLanguages, required this.onChanged, super.key});
  final List<String> selectedLanguages;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) => _ChipSelector(
    allOptions: availableLanguages, selectedValues: selectedLanguages,
    onChanged: onChanged, displayLabel: (option) => option,
  );
}

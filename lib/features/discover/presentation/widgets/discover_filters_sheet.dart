/// Bottom sheet for discovery filter controls.
///
/// Provides age range, distance, and gender preference filters.
/// Uses [TanderBottomSheet] for consistent slide-up modal behaviour.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/discover_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/user_settings_provider.dart';

const int _minDistanceKm = 1;
const int _maxDistanceKm = 500;

const List<({String? value, String label})> _genderOptions = [
  (value: null, label: 'Everyone'),
  (value: 'MALE', label: 'Men'),
  (value: 'FEMALE', label: 'Women'),
  (value: 'NON_BINARY', label: 'Non-binary'),
];

class DiscoverFiltersSheet extends ConsumerStatefulWidget {
  const DiscoverFiltersSheet({
    required this.activeFilters,
    required this.onApply,
    required this.configMinAge,
    required this.configMaxAge,
    super.key,
  });

  final DiscoveryFiltersDto? activeFilters;
  final void Function(DiscoveryFiltersDto?) onApply;
  final int configMinAge;
  final int configMaxAge;

  static Future<void> show({
    required BuildContext context,
    required DiscoveryFiltersDto? activeFilters,
    required void Function(DiscoveryFiltersDto?) onApply,
    required int configMinAge,
    required int configMaxAge,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (_) => DiscoverFiltersSheet(
        activeFilters: activeFilters,
        onApply: onApply,
        configMinAge: configMinAge,
        configMaxAge: configMaxAge,
      ),
    );
  }

  @override
  ConsumerState<DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

class _DiscoverFiltersSheetState extends ConsumerState<DiscoverFiltersSheet> {
  late int _filterMinAge;
  late int _filterMaxAge;
  late int _filterMaxDistanceKm;
  late String? _filterGenderPreference;

  @override
  void initState() {
    super.initState();
    final dto = widget.activeFilters;
    _filterMinAge = dto?.minAge ?? widget.configMinAge;
    _filterMaxAge = dto?.maxAge ?? widget.configMaxAge;
    _filterMaxDistanceKm = dto?.maxDistanceKm ?? _maxDistanceKm;
    _filterGenderPreference = dto?.genderPreference;
  }

  Future<void> _handleApply() async {
    // Save to user settings
    try {
      await ref.read(userSettingsProvider.notifier).updateSettings(
        UpdateSettingsRequestDto(
          discoveryMinAge: _filterMinAge,
          discoveryMaxAge: _filterMaxAge,
          discoveryMaxDistanceKm: _filterMaxDistanceKm,
        ),
      );
    } catch (_) {
      // Continue even if save fails — local filters still apply
    }

    widget.onApply(DiscoveryFiltersDto(
      minAge: _filterMinAge,
      maxAge: _filterMaxAge,
      maxDistanceKm: _filterMaxDistanceKm,
      genderPreference: _filterGenderPreference,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  void _handleReset() {
    setState(() {
      _filterMinAge = widget.configMinAge;
      _filterMaxAge = widget.configMaxAge;
      _filterMaxDistanceKm = _maxDistanceKm;
      _filterGenderPreference = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
          // Header
          _buildHeader(),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResetHeader(),
                  const Divider(height: 1, color: AppColors.border),
                  _buildAgeRangeSection(),
                  const Divider(height: 1, color: AppColors.border),
                  _buildDistanceSection(),
                  const Divider(height: 1, color: AppColors.border),
                  _buildGenderSection(),
                ],
              ),
            ),
          ),
          // Sticky Apply button
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: _buildApplyButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Filters', style: AppTypography.label),
        ],
      ),
    );
  }

  Widget _buildResetHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _handleReset,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Text(
              'Reset',
              style: AppTypography.label.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeRangeSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Age range', '${_filterMinAge} \u2013 ${_filterMaxAge}'),
          const SizedBox(height: AppSpacing.md),
          _buildSlider(
            label: 'Minimum',
            value: _filterMinAge.toDouble(),
            displayValue: '$_filterMinAge',
            min: widget.configMinAge.toDouble(),
            max: (_filterMaxAge - 1).toDouble(),
            onChanged: (v) => setState(() => _filterMinAge = v.round()),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSlider(
            label: 'Maximum',
            value: _filterMaxAge.toDouble(),
            displayValue: '$_filterMaxAge',
            min: (_filterMinAge + 1).toDouble(),
            max: widget.configMaxAge.toDouble(),
            onChanged: (v) => setState(() => _filterMaxAge = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceSection() {
    final String distanceLabel = _filterMaxDistanceKm >= _maxDistanceKm
        ? 'Anywhere'
        : '$_filterMaxDistanceKm km';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Maximum distance', distanceLabel),
          const SizedBox(height: AppSpacing.sm),
          _primarySlider(
            value: _filterMaxDistanceKm.toDouble(),
            min: _minDistanceKm.toDouble(),
            max: _maxDistanceKm.toDouble(),
            divisions: (_maxDistanceKm - _minDistanceKm) ~/ 5,
            onChanged: (v) => setState(() => _filterMaxDistanceKm = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_minDistanceKm km', style: AppTypography.caption),
              Text('Anywhere', style: AppTypography.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHOW ME',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._genderOptions.map((option) {
            final bool isSelected = _filterGenderPreference == option.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => setState(() => _filterGenderPreference = option.value),
                child: Container(
                  constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryLight : AppColors.card,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        option.label,
                        style: AppTypography.body.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textBody,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: GestureDetector(
        onTap: _handleApply,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFF07020), Color(0xFFE67E22)]),
            borderRadius: AppRadius.borderLg,
          ),
          alignment: Alignment.center,
          child: Text(
            'Apply filters',
            style: AppTypography.label.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────

  Widget _sectionHeader(String label, String displayValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        Text(displayValue, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required String displayValue,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            Text(displayValue, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        _primarySlider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _primarySlider({
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

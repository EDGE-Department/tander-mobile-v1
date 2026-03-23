/// Discovery settings screen with age range, distance, and gender preference.
///
/// All changes save immediately on interaction.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/section_label.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';
import 'package:tander_flutter_v3/shared/widgets/warm_switch.dart';

// ── Constants ───────────────────────────────────────────────────────────

const double _minAge = 60;
const double _maxAge = 100;
const double _defaultMinAge = 60;
const double _defaultMaxAge = 80;
const double _minDistanceKm = 1;
const double _maxDistanceKm = 500;
const double _defaultDistanceKm = 50;

const List<({String value, String label})> _genderPreferences = [
  (value: 'EVERYONE', label: 'Everyone'),
  (value: 'MEN', label: 'Men'),
  (value: 'WOMEN', label: 'Women'),
  (value: 'NON_BINARY', label: 'Non-binary'),
];

// ── Screen ──────────────────────────────────────────────────────────────

class SettingsDiscoveryScreen extends ConsumerStatefulWidget {
  const SettingsDiscoveryScreen({super.key});

  @override
  ConsumerState<SettingsDiscoveryScreen> createState() => _State();
}

class _State extends ConsumerState<SettingsDiscoveryScreen> {
  RangeValues _ageRange = const RangeValues(_defaultMinAge, _defaultMaxAge);
  double _distanceKm = _defaultDistanceKm;
  String _genderPreference = 'EVERYONE';
  bool _isHidden = false;

  void _showSavedToast() {
    TanderToastOverlay.show(context, const TanderToastData(
      message: 'Discovery preference saved.',
      variant: TanderToastVariant.success,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _distanceKm >= _maxDistanceKm
        ? 'Anywhere'
        : '${_distanceKm.round()} km';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
          tooltip: 'Back to settings',
        ),
        title: Text('Discovery', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SliderCard(
            title: 'Age range',
            badge: '${_ageRange.start.round()}\u2013${_ageRange.end.round()}',
            child: Column(children: [
              SliderTheme(
                data: _sliderTheme(context),
                child: RangeSlider(
                  values: _ageRange,
                  min: _minAge, max: _maxAge,
                  divisions: (_maxAge - _minAge).round(),
                  labels: RangeLabels('${_ageRange.start.round()}', '${_ageRange.end.round()}'),
                  onChanged: (values) => setState(() => _ageRange = values),
                  onChangeEnd: (_) => _showSavedToast(),
                ),
              ),
              _RangeLabelsRow(start: '${_minAge.round()}', end: '${_maxAge.round()}+'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          _SliderCard(
            title: 'Maximum distance',
            badge: distanceLabel,
            child: Column(children: [
              SliderTheme(
                data: _sliderTheme(context),
                child: Slider(
                  value: _distanceKm,
                  min: _minDistanceKm, max: _maxDistanceKm,
                  divisions: 99,
                  label: distanceLabel,
                  onChanged: (value) => setState(() => _distanceKm = value),
                  onChangeEnd: (_) => _showSavedToast(),
                ),
              ),
              const _RangeLabelsRow(start: '1 km', end: 'Anywhere'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionLabel(label: 'Interested in'),
          const SizedBox(height: AppSpacing.sm),
          _RadioGroup(
            selected: _genderPreference,
            options: _genderPreferences,
            onChanged: (value) { setState(() => _genderPreference = value); _showSavedToast(); },
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionLabel(label: 'Visibility'),
          const SizedBox(height: AppSpacing.sm),
          _HiddenToggleCard(
            isHidden: _isHidden,
            onToggle: () { setState(() => _isHidden = !_isHidden); _showSavedToast(); },
          ),
          if (_isHidden) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxs),
              child: Text(
                'Your profile is currently hidden from discovery.',
                style: AppTypography.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.subtle,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
      trackHeight: 4,
      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
    );
  }
}

// ── Slider card ─────────────────────────────────────────────────────────

class _SliderCard extends StatelessWidget {
  const _SliderCard({required this.title, required this.badge, required this.child});
  final String title;
  final String badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: AppTypography.label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.borderFull),
            child: Text(badge, style: AppTypography.label.copyWith(color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        child,
      ]),
    );
  }
}

// ── Range labels row ────────────────────────────────────────────────────

class _RangeLabelsRow extends StatelessWidget {
  const _RangeLabelsRow({required this.start, required this.end});
  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(start, style: AppTypography.caption),
      Text(end, style: AppTypography.caption),
    ]);
  }
}

// ── Radio group ─────────────────────────────────────────────────────────

class _RadioGroup extends StatelessWidget {
  const _RadioGroup({required this.selected, required this.options, required this.onChanged});
  final String selected;
  final List<({String value, String label})> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        for (int index = 0; index < options.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.border),
          _RadioRow(
            label: options[index].label,
            isSelected: selected == options[index].value,
            onTap: () => onChanged(options[index].value),
          ),
        ],
      ]),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        color: isSelected ? AppColors.subtle : null,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTypography.label.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textStrong,
          )),
          if (isSelected) _RadioDot(),
        ]),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle)),
    );
  }
}

// ── Hidden toggle card ──────────────────────────────────────────────────

class _HiddenToggleCard extends StatelessWidget {
  const _HiddenToggleCard({required this.isHidden, required this.onToggle});
  final bool isHidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.success, borderRadius: AppRadius.borderMd),
              alignment: Alignment.center,
              child: const Icon(Icons.visibility_off_outlined, size: 20, color: AppColors.textInverse),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hide from discovery', style: AppTypography.label),
              Text("Your profile won't appear to new people", style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            ])),
            WarmSwitch(isEnabled: isHidden, onToggle: onToggle),
          ]),
        ),
      ),
    );
  }
}

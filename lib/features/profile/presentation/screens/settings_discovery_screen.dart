/// Discovery settings screen with age range, distance, and gender preference.
///
/// All changes save immediately on interaction.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/providers/app_config_provider.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/user_settings_provider.dart';
import 'package:tander_flutter_v3/shared/widgets/section_label.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';
import 'package:tander_flutter_v3/shared/widgets/warm_switch.dart';

// ── Constants ───────────────────────────────────────────────────────────

const double _minDistanceKm = 1;
const double _maxDistanceKm = 500;

// ── Screen ──────────────────────────────────────────────────────────────

class SettingsDiscoveryScreen extends ConsumerStatefulWidget {
  const SettingsDiscoveryScreen({super.key});

  @override
  ConsumerState<SettingsDiscoveryScreen> createState() => _State();
}

class _State extends ConsumerState<SettingsDiscoveryScreen> {
  RangeValues? _ageRange;
  double? _distanceKm;
  bool? _isHidden;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _showSavedToast() {
    TanderToastOverlay.show(
      context,
      const TanderToastData(
        message: 'Discovery preference saved.',
        variant: TanderToastVariant.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _debouncedSave(UpdateSettingsRequestDto request) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(userSettingsProvider.notifier).updateSettings(request);
      _showSavedToast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final configAsync = ref.watch(appConfigProvider);

    if (settingsAsync.isLoading || configAsync.isLoading) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final settings = settingsAsync.valueOrNull;
    final config = configAsync.valueOrNull;

    if (settings == null || config == null) {
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
        body: const Center(child: Text('Failed to load settings.')),
      );
    }

    final minAgeLimit = config.discoveryMinAge.toDouble();
    final maxAgeLimit = config.discoveryMaxAge.toDouble();

    // Initialize local state from the backend if it's not set
    _ageRange ??= RangeValues(
      settings.discoveryMinAge.toDouble(),
      settings.discoveryMaxAge.toDouble(),
    );
    _distanceKm ??= settings.discoveryMaxDistanceKm.toDouble();
    _isHidden ??= !settings.discoveryVisible;

    final distanceLabel = _distanceKm! >= _maxDistanceKm
        ? 'Anywhere'
        : '${_distanceKm!.round()} km';

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
            badge: '${_ageRange!.start.round()}\u2013${_ageRange!.end.round()}',
            child: Column(children: [
              SliderTheme(
                data: _sliderTheme(context),
                child: RangeSlider(
                  values: _ageRange!,
                  min: minAgeLimit,
                  max: maxAgeLimit,
                  divisions: (maxAgeLimit - minAgeLimit).round(),
                  labels: RangeLabels(
                      '${_ageRange!.start.round()}', '${_ageRange!.end.round()}'),
                  onChanged: (values) {
                    setState(() => _ageRange = values);
                    _debouncedSave(UpdateSettingsRequestDto(
                      discoveryMinAge: values.start.round(),
                      discoveryMaxAge: values.end.round(),
                    ));
                  },
                ),
              ),
              _RangeLabelsRow(
                start: '${minAgeLimit.round()}',
                end: '${maxAgeLimit.round()}+',
              ),
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
                  value: _distanceKm!,
                  min: _minDistanceKm,
                  max: _maxDistanceKm,
                  divisions: 99,
                  label: distanceLabel,
                  onChanged: (value) {
                    setState(() => _distanceKm = value);
                    _debouncedSave(UpdateSettingsRequestDto(
                      discoveryMaxDistanceKm: value.round(),
                    ));
                  },
                ),
              ),
              const _RangeLabelsRow(start: '1 km', end: 'Anywhere'),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionLabel(label: 'Visibility'),
          const SizedBox(height: AppSpacing.sm),
          _HiddenToggleCard(
            isHidden: _isHidden!,
            onToggle: () {
              setState(() => _isHidden = !_isHidden!);
              ref.read(userSettingsProvider.notifier).updateSettings(
                    UpdateSettingsRequestDto(discoveryVisible: !_isHidden!),
                  );
              _showSavedToast();
            },
          ),
          if (_isHidden!) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxs),
              child: Text(
                'Your profile is currently hidden from discovery.',
                style: AppTypography.caption.copyWith(
                    color: AppColors.warning, fontWeight: FontWeight.w600),
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
  const _SliderCard(
      {required this.title, required this.badge, required this.child});
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.borderFull),
            child: Text(badge,
                style: AppTypography.label.copyWith(color: AppColors.primary)),
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
          constraints:
              const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.success, borderRadius: AppRadius.borderMd),
              alignment: Alignment.center,
              child: const Icon(Icons.visibility_off_outlined,
                  size: 20, color: AppColors.textInverse),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Hide from discovery', style: AppTypography.label),
                  Text("Your profile won't appear to new people",
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.textMuted)),
                ])),
            WarmSwitch(isEnabled: isHidden, onToggle: onToggle),
          ]),
        ),
      ),
    );
  }
}

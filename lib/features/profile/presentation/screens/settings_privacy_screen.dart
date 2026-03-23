/// Privacy settings screen with visibility radio buttons and toggles.
///
/// Profile visibility (Everyone, Connections Only, Hidden) and three
/// activity toggles that save immediately on change.
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

// ── Data definitions ────────────────────────────────────────────────────

const List<({String value, String label})> _visibilityOptions = [
  (value: 'PUBLIC', label: 'Everyone'),
  (value: 'CONNECTIONS_ONLY', label: 'Connections only'),
  (value: 'PRIVATE', label: 'Nobody'),
];

const List<({String id, IconData icon, String label, String description, bool defaultValue})> _privacyToggles = [
  (id: 'showOnlineStatus', icon: Icons.visibility_outlined, label: 'Show online status', description: "Let others see when you're active", defaultValue: true),
  (id: 'showLastActive', icon: Icons.visibility_off_outlined, label: 'Show last active', description: 'Display when you were last active', defaultValue: true),
  (id: 'allowConnectionRequests', icon: Icons.people_outline, label: 'Allow connection requests', description: 'Let everyone send you connection requests', defaultValue: true),
];

// ── Screen ──────────────────────────────────────────────────────────────

class SettingsPrivacyScreen extends ConsumerStatefulWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  ConsumerState<SettingsPrivacyScreen> createState() => _State();
}

class _State extends ConsumerState<SettingsPrivacyScreen> {
  String _visibility = 'PUBLIC';
  late final Map<String, bool> _toggles;

  @override
  void initState() {
    super.initState();
    _toggles = {for (final toggle in _privacyToggles) toggle.id: toggle.defaultValue};
  }

  void _showSavedToast() {
    TanderToastOverlay.show(context, const TanderToastData(
      message: 'Privacy setting updated.',
      variant: TanderToastVariant.success,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Privacy', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionLabel(label: 'Who can see my profile'),
          const SizedBox(height: AppSpacing.sm),
          _VisibilityRadioGroup(
            selected: _visibility,
            onChanged: (value) { setState(() => _visibility = value); _showSavedToast(); },
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel(label: 'Activity'),
          const SizedBox(height: AppSpacing.sm),
          _ToggleList(
            toggles: _toggles,
            onToggle: (toggleId) { setState(() { _toggles[toggleId] = !(_toggles[toggleId] ?? false); }); _showSavedToast(); },
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: Text(
            'Your privacy matters to us. Changes take effect immediately.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }
}

// ── Visibility radio group ──────────────────────────────────────────────

class _VisibilityRadioGroup extends StatelessWidget {
  const _VisibilityRadioGroup({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        for (int index = 0; index < _visibilityOptions.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.border),
          _RadioRow(
            label: _visibilityOptions[index].label,
            isSelected: selected == _visibilityOptions[index].value,
            onTap: () => onChanged(_visibilityOptions[index].value),
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
          if (isSelected)
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle)),
            ),
        ]),
      ),
    );
  }
}

// ── Toggle list ─────────────────────────────────────────────────────────

class _ToggleList extends StatelessWidget {
  const _ToggleList({required this.toggles, required this.onToggle});
  final Map<String, bool> toggles;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        for (int index = 0; index < _privacyToggles.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.border),
          _ToggleRow(
            icon: _privacyToggles[index].icon,
            label: _privacyToggles[index].label,
            description: _privacyToggles[index].description,
            isEnabled: toggles[_privacyToggles[index].id] ?? false,
            onToggle: () => onToggle(_privacyToggles[index].id),
          ),
        ],
      ]),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon, required this.label, required this.description,
    required this.isEnabled, required this.onToggle,
  });
  final IconData icon;
  final String label;
  final String description;
  final bool isEnabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadius.borderMd),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.textInverse),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTypography.label),
            Text(description, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
          ])),
          const SizedBox(width: AppSpacing.sm),
          WarmSwitch(isEnabled: isEnabled, onToggle: onToggle),
        ]),
      ),
    );
  }
}

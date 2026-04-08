/// Settings hub screen with navigation to sub-screens.
///
/// Organizes settings into logical sections (Account, Preferences,
/// Support, Actions) using [ActionCard] rows. Each row navigates
/// to a dedicated sub-screen via [GoRouter].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/shared/widgets/section_label.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_bottom_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_confirm_dialog.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';
import 'package:tander_flutter_v3/shared/widgets/warm_switch.dart';

/// Settings hub screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
          tooltip: 'Back to profile',
        ),
        title: Text('Settings', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(label: 'Account'),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () => _showSettingsSheet(
                context,
                title: 'Notifications',
                child: const _NotificationsSheetContent(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: Icons.visibility_outlined,
              label: 'Privacy',
              onTap: () => _showSettingsSheet(
                context,
                title: 'Privacy',
                child: const _PrivacySheetContent(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: Icons.verified_user,
              label: 'Security',
              onTap: () => _showSettingsSheet(
                context,
                title: 'Security',
                child: const _SecuritySheetContent(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeading(label: 'Preferences'),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: Icons.explore,
              label: 'Discovery Settings',
              onTap: () => _showSettingsSheet(
                context,
                title: 'Discovery',
                child: const _DiscoverySheetContent(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeading(label: 'Support'),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: Icons.help_outline,
              label: 'Help & FAQ',
              onTap: () => _showHelpSheet(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: Icons.info_outline,
              label: 'About Tander',
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeading(label: 'Actions'),
            const SizedBox(height: AppSpacing.xs),
            _SignOutCard(
              onTap: () => _handleSignOut(context, ref),
            ),
            const SizedBox(height: AppSpacing.xs),
            _DeleteAccountCard(
              onTap: () => _handleDeleteAccount(context, ref),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    TanderBottomSheet.show(
      context: context,
      title: title,
      maxHeightFraction: 0.85,
      child: child,
    );
  }

  void _showHelpSheet(BuildContext context) {
    TanderBottomSheet.show(
      context: context,
      title: 'Help & FAQ',
      child: const _HelpSheetPlaceholder(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Tander',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Dating & wellness for Filipino seniors 60+',
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final didConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Sign out?',
      message: 'You will need to sign in again to access your account.',
      confirmLabel: 'Sign out',
    );

    if (didConfirm != true) return;
    ref.read(authNotifierProvider.notifier).signOut();
  }

  Future<void> _handleDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final didConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Delete account?',
      message:
          'This action is permanent and cannot be undone. All your data, '
          'connections, and messages will be permanently deleted.',
      confirmLabel: 'Delete forever',
      isDanger: true,
    );

    if (didConfirm != true) return;

    // Second confirmation for destructive action
    final didDoubleConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Are you absolutely sure?',
      message:
          'There is no way to recover your account after deletion. '
          'This cannot be undone.',
      confirmLabel: 'Yes, delete my account',
      isDanger: true,
    );

    if (didDoubleConfirm != true) return;

    // Delegate to auth notifier (which calls the delete endpoint)
    ref.read(authNotifierProvider.notifier).signOut();
  }
}

// ── Private widgets ──────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppRadius.borderMd,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.logout, size: 18,
                    color: AppColors.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sign out',
                  style: AppTypography.label.copyWith(color: AppColors.warning),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: AppRadius.borderMd,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.delete_outline, size: 18,
                    color: AppColors.danger),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Delete account',
                  style: AppTypography.label.copyWith(color: AppColors.danger),
                ),
              ),
              const Icon(Icons.warning_amber, size: 16,
                  color: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSheetPlaceholder extends StatelessWidget {
  const _HelpSheetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Help content will be loaded here.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TanderButton(
            label: 'Close',
            variant: TanderButtonVariant.outline,
            size: TanderButtonSize.compact,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Settings sheet content widgets
// ═══════════════════════════════════════════════════════════════════════

class _NotificationsSheetContent extends StatefulWidget {
  const _NotificationsSheetContent();

  @override
  State<_NotificationsSheetContent> createState() =>
      _NotificationsSheetContentState();
}

class _NotificationsSheetContentState
    extends State<_NotificationsSheetContent> {
  final Map<String, bool> _toggles = {
    'messages': true,
    'connections': true,
    'profileViews': false,
    'community': true,
    'tandy': true,
  };

  static const _items = [
    (id: 'messages', icon: Icons.chat_bubble_outline, label: 'New messages', desc: 'Notify me when I receive a message'),
    (id: 'connections', icon: Icons.favorite, label: 'Connection requests', desc: 'Notify me when someone wants to connect'),
    (id: 'profileViews', icon: Icons.account_circle, label: 'Profile views', desc: 'Notify me when someone visits my profile'),
    (id: 'community', icon: Icons.campaign, label: 'Community activity', desc: 'Replies and reactions to my posts'),
    (id: 'tandy', icon: Icons.notifications_outlined, label: 'Tandy reminders', desc: 'Daily wellness check-in prompts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose which notifications you would like to receive.',
            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _SheetToggleRow(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    description: _items[i].desc,
                    isEnabled: _toggles[_items[i].id] ?? false,
                    onToggle: () => setState(() {
                      _toggles[_items[i].id] = !(_toggles[_items[i].id] ?? false);
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Push notifications require permission from your device settings.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PrivacySheetContent extends StatefulWidget {
  const _PrivacySheetContent();

  @override
  State<_PrivacySheetContent> createState() => _PrivacySheetContentState();
}

class _PrivacySheetContentState extends State<_PrivacySheetContent> {
  String _visibility = 'PUBLIC';
  final Map<String, bool> _toggles = {
    'showOnlineStatus': true,
    'showLastActive': true,
    'allowConnectionRequests': true,
  };

  static const _privacyToggles = [
    (id: 'showOnlineStatus', icon: Icons.visibility_outlined, label: 'Show online status', desc: "Let others see when you're active"),
    (id: 'showLastActive', icon: Icons.visibility_off_outlined, label: 'Show last active', desc: 'Display when you were last active'),
    (id: 'allowConnectionRequests', icon: Icons.people_outline, label: 'Allow connection requests', desc: 'Let everyone send you connection requests'),
  ];

  static const _visibilityOptions = [
    (value: 'PUBLIC', label: 'Everyone'),
    (value: 'CONNECTIONS_ONLY', label: 'Connections only'),
    (value: 'PRIVATE', label: 'Nobody'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Who can see my profile'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _visibilityOptions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _SheetRadioRow(
                    label: _visibilityOptions[i].label,
                    isSelected: _visibility == _visibilityOptions[i].value,
                    onTap: () => setState(() => _visibility = _visibilityOptions[i].value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel(label: 'Activity'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _privacyToggles.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _SheetToggleRow(
                    icon: _privacyToggles[i].icon,
                    label: _privacyToggles[i].label,
                    description: _privacyToggles[i].desc,
                    isEnabled: _toggles[_privacyToggles[i].id] ?? false,
                    onToggle: () => setState(() {
                      _toggles[_privacyToggles[i].id] = !(_toggles[_privacyToggles[i].id] ?? false);
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecuritySheetContent extends StatefulWidget {
  const _SecuritySheetContent();

  @override
  State<_SecuritySheetContent> createState() => _SecuritySheetContentState();
}

class _SecuritySheetContentState extends State<_SecuritySheetContent> {
  bool _isTwoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Two-factor authentication'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: _SheetToggleRow(
              icon: Icons.security,
              label: 'Enable 2FA',
              description: 'Add an extra layer of security',
              isEnabled: _isTwoFactorEnabled,
              onToggle: () => setState(() => _isTwoFactorEnabled = !_isTwoFactorEnabled),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionLabel(label: 'Data'),
          const SizedBox(height: AppSpacing.sm),
          ActionCard(
            icon: Icons.file_download_outlined,
            label: 'Export my data',
            onTap: () {
              TanderToastOverlay.show(
                context,
                const TanderToastData(
                  message: 'Your data export will be emailed to you shortly.',
                  variant: TanderToastVariant.info,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DiscoverySheetContent extends StatefulWidget {
  const _DiscoverySheetContent();

  @override
  State<_DiscoverySheetContent> createState() => _DiscoverySheetContentState();
}

class _DiscoverySheetContentState extends State<_DiscoverySheetContent> {
  RangeValues _ageRange = const RangeValues(60, 80);
  double _distanceKm = 50;
  String _genderPreference = 'EVERYONE';
  bool _isHidden = false;

  static const _genderOptions = [
    (value: 'EVERYONE', label: 'Everyone'),
    (value: 'MEN', label: 'Men'),
    (value: 'WOMEN', label: 'Women'),
    (value: 'NON_BINARY', label: 'Non-binary'),
  ];

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _distanceKm >= 500 ? 'Anywhere' : '${_distanceKm.round()} km';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age range
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Age range', style: AppTypography.label),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.borderFull),
                      child: Text('${_ageRange.start.round()}–${_ageRange.end.round()}',
                          style: AppTypography.label.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                RangeSlider(
                  values: _ageRange,
                  min: 60, max: 100,
                  divisions: 40,
                  activeColor: AppColors.primary,
                  onChanged: (values) => setState(() => _ageRange = values),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Distance
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Maximum distance', style: AppTypography.label),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.borderFull),
                      child: Text(distanceLabel,
                          style: AppTypography.label.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Slider(
                  value: _distanceKm,
                  min: 1, max: 500,
                  divisions: 99,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => _distanceKm = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Gender preference
          const SectionLabel(label: 'Interested in'),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _genderOptions.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _SheetRadioRow(
                    label: _genderOptions[i].label,
                    isSelected: _genderPreference == _genderOptions[i].value,
                    onTap: () => setState(() => _genderPreference = _genderOptions[i].value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Hidden toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border),
            ),
            child: _SheetToggleRow(
              icon: Icons.visibility_off_outlined,
              label: 'Hide from discovery',
              description: "Your profile won't appear to new people",
              isEnabled: _isHidden,
              onToggle: () => setState(() => _isHidden = !_isHidden),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sheet row widgets ────────────────────────────────────────────

class _SheetToggleRow extends StatelessWidget {
  const _SheetToggleRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.isEnabled,
    required this.onToggle,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryHover],
                ),
                borderRadius: AppRadius.borderMd,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.textInverse),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.label),
                  Text(description, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            WarmSwitch(isEnabled: isEnabled, onToggle: onToggle),
          ],
        ),
      ),
    );
  }
}

class _SheetRadioRow extends StatelessWidget {
  const _SheetRadioRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
          ],
        ),
      ),
    );
  }
}

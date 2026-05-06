/// Settings hub screen with navigation to sub-screens.
///
/// Organizes settings into logical sections (Account, Preferences,
/// Support, Actions) using [ActionCard] rows. Each row navigates
/// to a dedicated sub-screen via [GoRouter].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/user_settings_provider.dart';
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

class _NotificationsSheetContent extends ConsumerWidget {
  const _NotificationsSheetContent();

  static const _items = [
    (id: 'notifyMessages', icon: Icons.chat_bubble_outline, label: 'New messages', desc: 'Notify me when I receive a message'),
    (id: 'notifyMatches', icon: Icons.favorite, label: 'Connection requests', desc: 'Notify me when someone wants to connect'),
    (id: 'notifyProfileViews', icon: Icons.account_circle, label: 'Profile views', desc: 'Notify me when someone visits my profile'),
    (id: 'notifyCommunity', icon: Icons.campaign, label: 'Community activity', desc: 'Replies and reactions to my posts'),
    (id: 'notifyTandy', icon: Icons.notifications_outlined, label: 'Tandy reminders', desc: 'Daily wellness check-in prompts'),
  ];

  bool _getValue(UserSettings s, String id) => switch (id) {
    'notifyMessages' => s.notifyMessages,
    'notifyMatches' => s.notifyMatches,
    'notifyProfileViews' => s.notifyProfileViews,
    'notifyCommunity' => s.notifyCommunity,
    'notifyTandy' => s.notifyTandy,
    _ => false,
  };

  void _toggle(BuildContext context, WidgetRef ref, String id, bool current) {
    final next = !current;
    final req = switch (id) {
      'notifyMessages' => UpdateSettingsRequestDto(notifyMessages: next),
      'notifyMatches' => UpdateSettingsRequestDto(notifyMatches: next),
      'notifyProfileViews' => UpdateSettingsRequestDto(notifyProfileViews: next),
      'notifyCommunity' => UpdateSettingsRequestDto(notifyCommunity: next),
      'notifyTandy' => UpdateSettingsRequestDto(notifyTandy: next),
      _ => null,
    };
    if (req != null) {
      ref.read(userSettingsProvider.notifier).updateSettings(req);
      TanderToastOverlay.show(context, const TanderToastData(
        message: 'Preference saved.',
        variant: TanderToastVariant.success,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return _SettingsLoadOrError(
        hasError: settingsAsync.hasError,
        onRetry: () => ref.invalidate(userSettingsProvider),
      );
    }

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
                    isEnabled: _getValue(settings, _items[i].id),
                    onToggle: () => _toggle(context, ref, _items[i].id, _getValue(settings, _items[i].id)),
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

class _PrivacySheetContent extends ConsumerWidget {
  const _PrivacySheetContent();

  static const _privacyToggles = [
    (id: 'showOnline', icon: Icons.visibility_outlined, label: 'Show online status', desc: "Let others see when you're active"),
    (id: 'showLastSeen', icon: Icons.visibility_off_outlined, label: 'Show last seen', desc: 'Display when you were last active'),
    (id: 'showProfileViews', icon: Icons.people_outline, label: 'Show profile views', desc: "Share when you've visited someone's profile"),
  ];

  static const _visibilityOptions = [
    (value: 'PUBLIC', label: 'Everyone'),
    (value: 'MATCHES_ONLY', label: 'Connections only'),
    (value: 'PRIVATE', label: 'Nobody'),
  ];

  bool _getToggle(UserSettings s, String id) => switch (id) {
    'showOnline' => s.showOnline,
    'showLastSeen' => s.showLastSeen,
    'showProfileViews' => s.showProfileViews,
    _ => false,
  };

  void _handleToggle(BuildContext context, WidgetRef ref, String id, bool current) {
    final next = !current;
    final req = switch (id) {
      'showOnline' => UpdateSettingsRequestDto(showOnline: next),
      'showLastSeen' => UpdateSettingsRequestDto(showLastSeen: next),
      'showProfileViews' => UpdateSettingsRequestDto(showProfileViews: next),
      _ => null,
    };
    if (req != null) {
      ref.read(userSettingsProvider.notifier).updateSettings(req);
      _showSaved(context);
    }
  }

  void _handleVisibility(BuildContext context, WidgetRef ref, String value) {
    ref.read(userSettingsProvider.notifier).updateSettings(
      UpdateSettingsRequestDto(profileVisibility: value),
    );
    _showSaved(context);
  }

  void _showSaved(BuildContext context) {
    TanderToastOverlay.show(context, const TanderToastData(
      message: 'Privacy setting updated.',
      variant: TanderToastVariant.success,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return _SettingsLoadOrError(
        hasError: settingsAsync.hasError,
        onRetry: () => ref.invalidate(userSettingsProvider),
      );
    }

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
                    isSelected: settings.profileVisibility == _visibilityOptions[i].value,
                    onTap: () => _handleVisibility(context, ref, _visibilityOptions[i].value),
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
                    isEnabled: _getToggle(settings, _privacyToggles[i].id),
                    onToggle: () => _handleToggle(context, ref, _privacyToggles[i].id, _getToggle(settings, _privacyToggles[i].id)),
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

class _SecuritySheetContent extends ConsumerWidget {
  const _SecuritySheetContent();

  void _toggleTwoFactor(BuildContext context, WidgetRef ref, bool current) {
    final next = !current;
    ref.read(userSettingsProvider.notifier).updateSettings(
      UpdateSettingsRequestDto(twoFactorEnabled: next),
    );
    TanderToastOverlay.show(context, TanderToastData(
      message: next ? 'Two-factor authentication enabled.' : 'Two-factor authentication disabled.',
      variant: TanderToastVariant.success,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return _SettingsLoadOrError(
        hasError: settingsAsync.hasError,
        onRetry: () => ref.invalidate(userSettingsProvider),
      );
    }

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
              isEnabled: settings.twoFactorEnabled,
              onToggle: () => _toggleTwoFactor(context, ref, settings.twoFactorEnabled),
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

class _DiscoverySheetContent extends ConsumerStatefulWidget {
  const _DiscoverySheetContent();

  @override
  ConsumerState<_DiscoverySheetContent> createState() => _DiscoverySheetContentState();
}

class _DiscoverySheetContentState extends ConsumerState<_DiscoverySheetContent> {
  RangeValues? _ageRange;
  double? _distanceKm;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _debouncedSave(UpdateSettingsRequestDto req) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(userSettingsProvider.notifier).updateSettings(req);
      _showSaved();
    });
  }

  void _showSaved() {
    TanderToastOverlay.show(context, const TanderToastData(
      message: 'Discovery preference saved.',
      variant: TanderToastVariant.success,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
      return _SettingsLoadOrError(
        hasError: settingsAsync.hasError,
        onRetry: () => ref.invalidate(userSettingsProvider),
      );
    }

    _ageRange ??= RangeValues(
      settings.discoveryMinAge.toDouble().clamp(60, 100),
      settings.discoveryMaxAge.toDouble().clamp(60, 100),
    );
    _distanceKm ??= settings.discoveryMaxDistanceKm.toDouble().clamp(1, 500);

    final distanceLabel = _distanceKm! >= 500 ? 'Anywhere' : '${_distanceKm!.round()} km';

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
                      child: Text('${_ageRange!.start.round()}–${_ageRange!.end.round()}',
                          style: AppTypography.label.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                RangeSlider(
                  values: _ageRange!,
                  min: 60, max: 100,
                  divisions: 40,
                  activeColor: AppColors.primary,
                  onChanged: (values) {
                    setState(() => _ageRange = values);
                    _debouncedSave(UpdateSettingsRequestDto(
                      discoveryMinAge: values.start.round(),
                      discoveryMaxAge: values.end.round(),
                    ));
                  },
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
                  value: _distanceKm!,
                  min: 1, max: 500,
                  divisions: 99,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _distanceKm = value);
                    _debouncedSave(UpdateSettingsRequestDto(
                      discoveryMaxDistanceKm: value.round(),
                    ));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Visibility toggle
          const SectionLabel(label: 'Visibility'),
          const SizedBox(height: AppSpacing.sm),
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
              isEnabled: !settings.discoveryVisible,
              onToggle: () {
                ref.read(userSettingsProvider.notifier).updateSettings(
                  UpdateSettingsRequestDto(discoveryVisible: !settings.discoveryVisible),
                );
                _showSaved();
              },
            ),
          ),
          if (!settings.discoveryVisible) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxs),
              child: Text(
                'Your profile is currently hidden from discovery.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

class _SettingsLoadOrError extends StatelessWidget {
  const _SettingsLoadOrError({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
                  const SizedBox(height: AppSpacing.sm),
                  Text("Couldn't load settings.", style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(onPressed: onRetry, child: const Text('Try again')),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

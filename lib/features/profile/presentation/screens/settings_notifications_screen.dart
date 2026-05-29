/// Notification settings screen with toggle switches.
///
/// Five notification toggles that save immediately on change. Uses
/// [ConsumerStatefulWidget] to hold local toggle state and persist
/// changes via the profile repository.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/contracts/profile_contracts.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/user_settings_provider.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';
import 'package:tander_flutter_v3/shared/widgets/warm_switch.dart';

// ── Toggle item definition ──────────────────────────────────────────────

class _NotificationToggleItem {
  const _NotificationToggleItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
  });

  final String id;
  final IconData icon;
  final String label;
  final String description;
}

const List<_NotificationToggleItem> _toggleItems = [
  _NotificationToggleItem(
    id: 'notifyMessages',
    icon: Icons.chat_bubble_outline,
    label: 'New messages',
    description: 'Notify me when I receive a message',
  ),
  _NotificationToggleItem(
    id: 'notifyMatches',
    icon: Icons.favorite,
    label: 'Connection requests',
    description: 'Notify me when someone wants to connect',
  ),
  _NotificationToggleItem(
    id: 'notifyProfileViews',
    icon: Icons.account_circle,
    label: 'Profile views',
    description: 'Notify me when someone visits my profile',
  ),
  _NotificationToggleItem(
    id: 'notifyCommunity',
    icon: Icons.campaign,
    label: 'Community activity',
    description: 'Replies and reactions to my posts',
  ),
  _NotificationToggleItem(
    id: 'notifyTandy',
    icon: Icons.notifications_outlined,
    label: 'Tandy reminders',
    description: 'Daily wellness check-in prompts',
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────

/// Notification preferences with immediate-save toggles.
class SettingsNotificationsScreen extends ConsumerWidget {
  const SettingsNotificationsScreen({super.key});

  void _handleToggle(
    BuildContext context,
    WidgetRef ref,
    String toggleId,
    bool currentValue,
  ) {
    final nextValue = !currentValue;

    switch (toggleId) {
      case 'notifyMessages':
        ref
            .read(userSettingsProvider.notifier)
            .updateSettings(
              UpdateSettingsRequestDto(notifyMessages: nextValue),
            );
        break;
      case 'notifyMatches':
        ref
            .read(userSettingsProvider.notifier)
            .updateSettings(UpdateSettingsRequestDto(notifyMatches: nextValue));
        break;
      case 'notifyProfileViews':
        ref
            .read(userSettingsProvider.notifier)
            .updateSettings(
              UpdateSettingsRequestDto(notifyProfileViews: nextValue),
            );
        break;
      case 'notifyCommunity':
        ref
            .read(userSettingsProvider.notifier)
            .updateSettings(
              UpdateSettingsRequestDto(notifyCommunity: nextValue),
            );
        break;
      case 'notifyTandy':
        ref
            .read(userSettingsProvider.notifier)
            .updateSettings(UpdateSettingsRequestDto(notifyTandy: nextValue));
        break;
    }

    TanderToastOverlay.show(
      context,
      const TanderToastData(
        message: 'Preference saved.',
        variant: TanderToastVariant.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    if (settingsAsync.isLoading) {
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
          title: Text('Notifications', style: AppTypography.h3),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final settings = settingsAsync.valueOrNull;

    if (settings == null) {
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
          title: Text('Notifications', style: AppTypography.h3),
        ),
        body: const Center(child: Text('Failed to load settings.')),
      );
    }

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
        title: Text('Notifications', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
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
                  for (int index = 0; index < _toggleItems.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 1, color: AppColors.border),
                    _ToggleRow(
                      icon: _toggleItems[index].icon,
                      label: _toggleItems[index].label,
                      description: _toggleItems[index].description,
                      isEnabled: _getSettingValue(
                        settings,
                        _toggleItems[index].id,
                      ),
                      onToggle: () => _handleToggle(
                        context,
                        ref,
                        _toggleItems[index].id,
                        _getSettingValue(settings, _toggleItems[index].id),
                      ),
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
      ),
    );
  }

  bool _getSettingValue(UserSettings settings, String id) {
    switch (id) {
      case 'notifyMessages':
        return settings.notifyMessages;
      case 'notifyMatches':
        return settings.notifyMatches;
      case 'notifyProfileViews':
        return settings.notifyProfileViews;
      case 'notifyCommunity':
        return settings.notifyCommunity;
      case 'notifyTandy':
        return settings.notifyTandy;
      default:
        return false;
    }
  }
}

// ── Toggle row ──────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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
        constraints: const BoxConstraints(
          minHeight: AppSpacing.touchComfortable,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                  Text(
                    description,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
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

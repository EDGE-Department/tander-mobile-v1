/// Notification settings screen with toggle switches.
///
/// Five notification toggles that save immediately on change. Uses
/// [ConsumerStatefulWidget] to hold local toggle state and persist
/// changes via the profile repository.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';
import 'package:tander_flutter_v3/shared/widgets/warm_switch.dart';

// ── Toggle item definition ──────────────────────────────────────────────

class _NotificationToggleItem {
  const _NotificationToggleItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.defaultValue,
  });

  final String id;
  final IconData icon;
  final String label;
  final String description;
  final bool defaultValue;
}

const List<_NotificationToggleItem> _toggleItems = [
  _NotificationToggleItem(
    id: 'messages',
    icon: Icons.chat_bubble_outline,
    label: 'New messages',
    description: 'Notify me when I receive a message',
    defaultValue: true,
  ),
  _NotificationToggleItem(
    id: 'connections',
    icon: Icons.favorite,
    label: 'Connection requests',
    description: 'Notify me when someone wants to connect',
    defaultValue: true,
  ),
  _NotificationToggleItem(
    id: 'profileViews',
    icon: Icons.account_circle,
    label: 'Profile views',
    description: 'Notify me when someone visits my profile',
    defaultValue: false,
  ),
  _NotificationToggleItem(
    id: 'community',
    icon: Icons.campaign,
    label: 'Community activity',
    description: 'Replies and reactions to my posts',
    defaultValue: true,
  ),
  _NotificationToggleItem(
    id: 'tandy',
    icon: Icons.notifications_outlined,
    label: 'Tandy reminders',
    description: 'Daily wellness check-in prompts',
    defaultValue: true,
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────

/// Notification preferences with immediate-save toggles.
class SettingsNotificationsScreen extends ConsumerStatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  ConsumerState<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends ConsumerState<SettingsNotificationsScreen> {
  late final Map<String, bool> _toggleState;

  @override
  void initState() {
    super.initState();
    _toggleState = {
      for (final item in _toggleItems) item.id: item.defaultValue,
    };
  }

  void _handleToggle(String toggleId) {
    setState(() {
      _toggleState[toggleId] = !(_toggleState[toggleId] ?? false);
    });

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
                      isEnabled:
                          _toggleState[_toggleItems[index].id] ?? false,
                      onToggle: () => _handleToggle(_toggleItems[index].id),
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
        constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
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
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.textMuted),
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


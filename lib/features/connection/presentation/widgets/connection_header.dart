/// Header and segmented tab bar for the connection screen.
///
/// Extracted from connection_screen.dart to keep each file under 400 lines.
library;

import 'package:flutter/material.dart' hide ConnectionState;

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/connection/presentation/states/connection_state.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_badge.dart';

// ── Tab enum ────────────────────────────────────────────────────────

/// The three connection tabs — matches the web's ActiveTab type.
enum ConnectionTab { incoming, sent, connected }

// ── Header ──────────────────────────────────────────────────────────

/// Icon, title, stat pills, and segmented tab bar above the connection lists.
class ConnectionHeader extends StatelessWidget {
  const ConnectionHeader({
    required this.activeTab,
    required this.connectionState,
    required this.onTabChanged,
    super.key,
  });

  final ConnectionTab activeTab;
  final ConnectionState connectionState;
  final ValueChanged<ConnectionTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final (pendingCount, friendsCount) = _resolveCounts();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(),
          if (pendingCount > 0 || friendsCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _buildStatsPills(
              pendingCount: pendingCount,
              friendsCount: friendsCount,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          ConnectionSegmentedTabBar(
            activeTab: activeTab,
            onTabChanged: onTabChanged,
            connectionState: connectionState,
          ),
        ],
      ),
    );
  }

  (int, int) _resolveCounts() {
    if (connectionState is ConnectionLoaded) {
      final loaded = connectionState as ConnectionLoaded;
      return (loaded.pendingCount, loaded.friendsCount);
    }
    return (0, 0);
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(-0.7, -1),
              end: Alignment(0.7, 1),
              colors: [Color(0xFF0F9D94), Color(0xFF0A7C74)],
            ),
            borderRadius: AppRadius.borderLg,
            boxShadow: AppShadows.warmXs,
          ),
          child: const Center(
            child: Icon(Icons.people, size: 24, color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connections', style: AppTypography.h1),
            const SizedBox(height: 2),
            Text(
              'Your people, your circle',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsPills({
    required int pendingCount,
    required int friendsCount,
  }) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        if (pendingCount > 0)
          TanderBadge(
            label: '$pendingCount pending',
            variant: TanderBadgeVariant.primary,
            icon: Icons.favorite,
          ),
        if (friendsCount > 0)
          TanderBadge(
            label: '$friendsCount ${friendsCount == 1 ? 'friend' : 'friends'}',
            variant: TanderBadgeVariant.secondary,
            icon: Icons.people,
          ),
      ],
    );
  }
}

// ── Segmented Tab Bar ───────────────────────────────────────────────

/// Rounded segmented control with animated gradient pill indicator.
///
/// Spring stiffness 420, damping 32 from the web — approximated via a
/// 250 ms cubic-bezier transition on the container decoration.
class ConnectionSegmentedTabBar extends StatelessWidget {
  const ConnectionSegmentedTabBar({
    required this.activeTab,
    required this.onTabChanged,
    required this.connectionState,
    super.key,
  });

  final ConnectionTab activeTab;
  final ValueChanged<ConnectionTab> onTabChanged;
  final ConnectionState connectionState;

  static const _tabPillGradient = LinearGradient(
    begin: Alignment(-0.7, -1),
    end: Alignment(0.7, 1),
    colors: [Color(0xFFF07020), Color(0xFFE67E22)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(ConnectionTab.incoming, 'Requests'),
          const SizedBox(width: 2),
          _buildTab(ConnectionTab.sent, 'Sent'),
          const SizedBox(width: 2),
          _buildTab(ConnectionTab.connected, 'Friends'),
        ],
      ),
    );
  }

  Widget _buildTab(ConnectionTab tab, String label) {
    final isActive = tab == activeTab;
    final count = _countForTab(tab);
    final hasItems = count > 0;

    return GestureDetector(
      onTap: () => onTabChanged(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
        constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? _tabPillGradient : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x59E67E22),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textMuted,
              ),
            ),
            if (isActive && hasItems) ...[
              const SizedBox(width: 6),
              _buildActiveCountBadge(count),
            ],
            if (!isActive && hasItems) ...[
              const SizedBox(width: 6),
              _buildInactiveDot(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCountBadge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: AppRadius.borderFull,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInactiveDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  int _countForTab(ConnectionTab tab) {
    if (connectionState is! ConnectionLoaded) return 0;
    final loaded = connectionState as ConnectionLoaded;
    return switch (tab) {
      ConnectionTab.incoming => loaded.pendingCount,
      ConnectionTab.sent => loaded.sentCount,
      ConnectionTab.connected => loaded.friendsCount,
    };
  }
}

// ── Header Divider ──────────────────────────────────────────────────

/// Gradient divider line between the header and tab panels.
class ConnectionHeaderDivider extends StatelessWidget {
  const ConnectionHeaderDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppColors.border, Colors.transparent],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

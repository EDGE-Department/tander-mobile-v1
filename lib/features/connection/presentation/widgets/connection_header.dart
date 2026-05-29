/// Header and segmented tab bar for the connection screen.
///
/// Extracted from connection_screen.dart to keep each file under 400 lines.
/// Matches connection-page.tsx: gradient icon, stats pills, animated tab bar.
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

/// The three connection tabs -- matches the web's ActiveTab type.
enum ConnectionTab { incoming, sent, connected }

// ── Header ──────────────────────────────────────────────────────────

/// Icon, title, stat pills, and segmented tab bar above the connection lists.
///
/// Web parity: gradient icon (135deg, #0F9D94 -> #0a7c74) in 48px
/// rounded-2xl container, Users icon 24px, "Connections" title, stats pills,
/// segmented tab bar with animated gradient pill.
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

    return Stack(
      children: [
        // Radial gradient background glow
        // Web: radial-gradient(ellipse, rgba(15,157,148,.12) 0%,
        //      rgba(230,126,34,.07) 45%, transparent 70%)
        // 700px wide, positioned -top-20, h-72
        Positioned(
          top: -80,
          left: 0,
          right: 0,
          height: 290,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    Color(0x1F0F9D94), // rgba(15,157,148,.12)
                    Color(0x12E67E22), // rgba(230,126,34,.07)
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.45, 0.70],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg + 4, // pt-10 (40px) minus SafeArea
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
        ),
      ],
    );
  }

  (int, int) _resolveCounts() {
    if (connectionState is ConnectionLoaded) {
      final loaded = connectionState as ConnectionLoaded;
      return (loaded.pendingCount, loaded.friendsCount);
    }
    return (0, 0);
  }

  /// Web: 48px rounded-2xl gradient icon + title column
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connections',
                style: AppTypography.h1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Your people, your circle',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Web: stats pills — Heart icon 11px + "{N} pending", Users icon 11px
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
/// Web: rounded-[18px] border bg-subtle p-1.5, tabs min-h 44px px-5
/// radius-[12px], active gradient(135deg, #F07020 -> #E67E22) white text,
/// shadow 0 3px 12px rgba(230,126,34,0.35), spring stiffness 420 damping 32.
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(6), // p-1.5
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
                    color: Color(0x59E67E22), // rgba(230,126,34,0.35)
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

  /// Web: h-5 min-w-[20px] rounded-full bg-white/20 text-[10px]
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
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Web: h-2 w-2 rounded-full bg-primary (8px orange dot)
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
/// Web: h-px mx-6 linear-gradient(90deg, transparent 0%, border 20%,
///      border 80%, transparent 100%)
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
            colors: [
              Colors.transparent,
              AppColors.border,
              AppColors.border,
              Colors.transparent,
            ],
            stops: [0.0, 0.2, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}

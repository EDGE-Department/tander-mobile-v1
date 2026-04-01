import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Top header nav bar matching the web's desktop layout.
///
/// Web: glass-morphism header bar, fixed top, 76px height,
/// centered tabs with active orange pill, logo left, user right.
class TanderTopNavBar extends ConsumerWidget {
  const TanderTopNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final badges = ref.watch(navBadgeProvider);
    final safeTop = MediaQuery.viewPaddingOf(context).top;

    return Container(
      padding: EdgeInsets.only(top: safeTop),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F5),
        border: Border(
          bottom: BorderSide(
            color: Color(0x1AE67E22), // rgba(230,126,34,0.10)
          ),
        ),
      ),
      child: SizedBox(
        height: 76,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              // Logo
              GestureDetector(
                onTap: () => context.go(AppRoutes.discover),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/tander_icon.png',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Tander',
                      style: AppTypography.brandWordmark(
                        fontSize: 22,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Center tabs
              _buildTabs(context, location, badges),

              const Spacer(),

              // Right: placeholder for user avatar
              const SizedBox(width: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(
    BuildContext context,
    String location,
    NavBadgeCounts badges,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < navTabs.length; i++) ...[
          _TopNavTab(
            tab: navTabs[i],
            isActive: _isActive(location, navTabs[i].route),
            badge: _badgeFor(i, badges),
            onTap: () => context.go(navTabs[i].route),
          ),
        ],
      ],
    );
  }

  bool _isActive(String location, String route) {
    return location == route || location.startsWith('$route/');
  }

  int _badgeFor(int index, NavBadgeCounts badges) {
    if (navTabs[index].route == AppRoutes.messages) return badges.unreadMessageCount;
    if (navTabs[index].route == AppRoutes.connection) {
      return badges.pendingConnectionCount;
    }
    return 0;
  }
}

class _TopNavTab extends StatelessWidget {
  const _TopNavTab({
    required this.tab,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

  final NavTabDescriptor tab;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isActive
              ? const LinearGradient(
                  begin: Alignment(-0.3, -1),
                  end: Alignment(0.3, 1),
                  colors: [Color(0xFFF07020), Color(0xFFDF5C08)],
                )
              : null,
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x70E05C08),
                    blurRadius: 22,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                tab.usesIconData
                    ? Icon(
                        isActive
                            ? (tab.activeIconData ?? tab.iconData!)
                            : tab.iconData!,
                        size: 24,
                        color: isActive
                            ? Colors.white
                            : (tab.iconColor ?? AppColors.textMuted),
                      )
                    : Image.asset(
                        tab.iconAsset!,
                        width: 24,
                        height: 24,
                        color: isActive ? Colors.white : AppColors.textMuted,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -5,
                    child: NavUnreadBadge(count: badge),
                  ),
              ],
            ),
            const SizedBox(width: 9),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

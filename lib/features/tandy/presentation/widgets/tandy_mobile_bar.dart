/// Mobile-only header and feature bar for the Tandy hub screen.
///
/// Extracted from tandy_screen.dart to keep each file under 400 lines.
/// Matches web tandy-mobile-bar.tsx: MobileHeader and MobileFeatureBar.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

// ── Mobile Header ───────────────────────────────────────────────────

/// Web: flex lg:hidden, avatar 40px with glow, "Tandy" 15px/800,
/// "Your Wellness Companion" 11px, online badge with teal dot.
class TandyMobileHeader extends StatelessWidget {
  const TandyMobileHeader({
    this.onClearTap,
    super.key,
  });

  final VoidCallback? onClearTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 16,
        right: 12,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF6ED),
              border: Border.all(color: kTandyOrange.withAlpha(50), width: 2),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/tandy_icon.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tandy',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textStrong,
              ),
            ),
          ),
          if (onClearTap != null)
            Material(
              color: const Color(0xFFF5F3F0),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onClearTap,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.refresh, color: Color(0xFFB0A8A0), size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Quick Actions Bar (60+ friendly) ────────────────────────────────

class TandyQuickActionsBar extends StatelessWidget {
  const TandyQuickActionsBar({
    required this.onChatTap,
    required this.onBreatheTap,
    required this.onMeditateTap,
    required this.onSupportTap,
    super.key,
  });

  final VoidCallback onChatTap;
  final VoidCallback onBreatheTap;
  final VoidCallback onMeditateTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          _QuickTab(label: 'Chat', icon: Icons.chat_bubble_outline, color: kTandyOrange, onTap: onChatTap),
          const SizedBox(width: 8),
          _QuickTab(label: 'Breathe', icon: Icons.spa_outlined, color: kTandyTeal, onTap: onBreatheTap),
          const SizedBox(width: 8),
          _QuickTab(label: 'Meditate', icon: Icons.self_improvement, color: kTandyPurple, onTap: onMeditateTap),
          const SizedBox(width: 8),
          _QuickTab(label: 'Support', icon: Icons.favorite_outline, color: kTandyBlue, onTap: onSupportTap),
        ],
      ),
    );
  }
}

class _QuickTab extends StatelessWidget {
  const _QuickTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E4E0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

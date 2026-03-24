/// Header and feature chips bar for the full-screen Tandy chat.
///
/// Extracted from tandy_chat_screen.dart to keep each file under 400 lines.
/// Matches web tandy-chat-page.tsx header and CHIPS array.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

// ── Chat Header ─────────────────────────────────────────────────────

/// Web: header with back button (42x42 rounded-[13px] border), Tandy avatar
/// (42x42 circle with glow), title ("Tandy" 17px/800, online status),
/// and clear button.
class TandyChatHeader extends StatelessWidget {
  const TandyChatHeader({
    required this.onBack,
    required this.onClear,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF0FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: <Widget>[
          // Back button (web: 42x42 rounded-[13px] border #E8E3DA bg white)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
            style: IconButton.styleFrom(
              fixedSize: const Size(42, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),

          // Tandy avatar (web: 42x42 circle gradient(135deg,#FEF0E0,#FDE8CC)
          // border 2px rgba(230,126,34,.30), glow animation)
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFEF0E0), Color(0xFFFDE8CC)],
              ),
              border: Border.all(
                color: kTandyOrange.withAlpha(77),
                width: 2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: kTandyOrange.withAlpha(56),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/tandy_icon.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 11),

          // Title + online status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tandy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textStrong,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.success.withAlpha(102),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Online \u00B7 Your companion',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTandyGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Clear button (web: 42x42 rounded-[13px] transparent)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline, size: 16),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Chips Bar ──────────────────────────────────────────────────

/// Web: flex gap-2 overflow-x-auto, paddingInline 12, borderBlockStart #E8E3DA,
/// bg rgba(255,255,255,0.96). Three chips: Breathe (teal bg #E0F5F4),
/// Meditate (purple bg #EDE9FE), Support (blue bg #DBEAFE).
class TandyChatChipsBar extends StatelessWidget {
  const TandyChatChipsBar({
    required this.onBreatheTap,
    required this.onMeditateTap,
    required this.onSupportTap,
    super.key,
  });

  final VoidCallback onBreatheTap;
  final VoidCallback onMeditateTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xF5FFFFFF),
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          _ChatFeatureChip(
            label: 'Breathe',
            icon: Icons.spa,
            color: kTandyTeal,
            backgroundColor: const Color(0xFFE0F5F4),
            onTap: onBreatheTap,
          ),
          const SizedBox(width: 8),
          _ChatFeatureChip(
            label: 'Meditate',
            icon: Icons.self_improvement,
            color: kTandyPurple,
            backgroundColor: const Color(0xFFEDE9FE),
            onTap: onMeditateTap,
          ),
          const SizedBox(width: 8),
          _ChatFeatureChip(
            label: 'Support',
            icon: Icons.person_outline,
            color: kTandyBlue,
            backgroundColor: const Color(0xFFDBEAFE),
            onTap: onSupportTap,
          ),
        ],
      ),
    );
  }
}

/// Web: padding 7px 15px, rounded-full, border 1.5px color+35, bg matching,
/// fontSize 12.5, fontWeight 600.
class _ChatFeatureChip extends StatelessWidget {
  const _ChatFeatureChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(55), width: 1.5),
          color: backgroundColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

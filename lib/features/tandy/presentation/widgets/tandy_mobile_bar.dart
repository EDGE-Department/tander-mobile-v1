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
  const TandyMobileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 16,
        right: 16,
        bottom: 11,
      ),
      decoration: const BoxDecoration(
        color: Color(0xF8FFFFFF), // rgba(255,255,255,.97)
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: <Widget>[
          // Avatar with glow
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFFF9F2), Color(0xFFFFF0DC)],
                  ),
                  border: Border.all(
                    color: kTandyOrange.withAlpha(64),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: kTandyOrange.withAlpha(31),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child:
                      Image.asset(
                        'assets/icons/tandy_icon.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4ADE80),
                    border: Border.all(color: AppColors.canvas, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tandy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textStrong,
                    letterSpacing: -0.45,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your Wellness Companion',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0C8078),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Online badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: <Color>[
                  kTandyTeal.withAlpha(20),
                  kTandyTeal.withAlpha(10),
                ],
              ),
              border: Border.all(color: kTandyTeal.withAlpha(46)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kTandyTeal,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: kTandyTeal.withAlpha(128),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0C8078),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Feature Bar ──────────────────────────────────────────────

/// Web: lg:hidden, grid 4 cols (Chat/Breathe/Meditate/Support) + clear button.
class TandyMobileFeatureBar extends StatelessWidget {
  const TandyMobileFeatureBar({
    required this.onChatTap,
    required this.onBreatheTap,
    required this.onMeditateTap,
    required this.onSupportTap,
    required this.onClearTap,
    super.key,
  });

  final VoidCallback onChatTap;
  final VoidCallback onBreatheTap;
  final VoidCallback onMeditateTap;
  final VoidCallback onSupportTap;
  final VoidCallback onClearTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.canvas.withAlpha(247),
        border: const Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // 4-col feature grid
          Row(
            children: <Widget>[
              _buildFeatureCell(
                label: 'Chat',
                icon: Icons.send_rounded,
                color: kTandyOrange,
                onTap: onChatTap,
              ),
              const SizedBox(width: 6),
              _buildFeatureCell(
                label: 'Breathe',
                icon: Icons.spa,
                color: kTandyTeal,
                onTap: onBreatheTap,
              ),
              const SizedBox(width: 6),
              _buildFeatureCell(
                label: 'Meditate',
                icon: Icons.self_improvement,
                color: kTandyPurple,
                onTap: onMeditateTap,
              ),
              const SizedBox(width: 6),
              _buildFeatureCell(
                label: 'Support',
                icon: Icons.person_outline,
                color: kTandyBlue,
                onTap: onSupportTap,
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Clear button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onClearTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.danger.withAlpha(46),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.delete_outline, size: 11,
                        color: Color(0xFFC0392B)),
                    SizedBox(width: 5),
                    Text(
                      'Clear conversation',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC0392B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCell({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(38)),
            color: Colors.white.withAlpha(179),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: color,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withAlpha(37),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

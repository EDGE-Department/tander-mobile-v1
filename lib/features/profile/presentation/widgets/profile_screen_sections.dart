/// Action row + re-exports for the My Profile screen.
///
/// The action row sits directly below the hero. Other content sections
/// live in `profile_content_sections.dart` and data builders in
/// `profile_section_builders.dart`; both are re-exported from here so
/// `profile_screen.dart` only imports a single file.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// Re-export so callers can import everything from one file.
export 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_content_sections.dart';
export 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_section_builders.dart';

// ── Action row ─────────────────────────────────────────────────────────

/// Web: `flex items-center gap-4`
///   - Edit Profile: `flex-1 h-14 rounded-[24px] bg-primary text-white`
///   - Settings / Help: `w-14 h-14 rounded-[24px] border-2 bg-white` icon-only
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    required this.onEdit,
    required this.onPhotos,
    required this.onSettings,
    required this.onHelp,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80E67E22),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    spreadRadius: -8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, size: 20, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Profile',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _IconAction(icon: Icons.settings, onTap: onSettings),
        const SizedBox(width: 16),
        _IconAction(icon: Icons.help_outline, onTap: onHelp),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppColors.textBody),
      ),
    );
  }
}

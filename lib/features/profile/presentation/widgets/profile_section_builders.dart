/// Data holders and pure builder functions for profile sections.
///
/// Contains: [CompletionTipData], [FactRowData], [buildSnapshotItems],
/// [buildDetailItems], [buildCompletionTips].
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:tander_flutter_v3/features/profile/presentation/screens/profile_photos_screen.dart';

import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';

// ── Data holders ───────────────────────────────────────────────────────

/// Data holder for a completion tip.
class CompletionTipData {
  const CompletionTipData({
    required this.label,
    required this.actionLabel,
    required this.boost,
    required this.onTap,
  });

  final String label;
  final String actionLabel;
  final String boost;
  final VoidCallback onTap;
}

/// Data holder for a snapshot/detail fact row.
class FactRowData {
  const FactRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

// ── Builder functions ──────────────────────────────────────────────────

/// Builds snapshot items (location, age, gender, looking for).
List<FactRowData> buildSnapshotItems({
  required String displayLocation,
  required int? age,
  required String? gender,
  required String? lookingFor,
}) {
  return [
    if (displayLocation.isNotEmpty)
      FactRowData(
        icon: Icons.location_on,
        label: 'Location',
        value: displayLocation,
      ),
    if (age != null)
      FactRowData(
        icon: Icons.calendar_today,
        label: 'Age',
        value: '$age years old',
      ),
    if (gender != null)
      FactRowData(
        icon: Icons.people,
        label: 'Gender',
        value: gender,
      ),
    if (lookingFor != null)
      FactRowData(
        icon: Icons.favorite,
        label: 'Looking for',
        value: lookingFor,
      ),
  ];
}

/// Builds detail items (hobby, civil status, religion, etc.).
List<FactRowData> buildDetailItems(UserProfile profile) {
  return [
    if (profile.hobby != null && profile.hobby!.trim().isNotEmpty)
      FactRowData(
        icon: Icons.favorite,
        label: 'Hobby',
        value: profile.hobby!.trim(),
      ),
    if (profile.civilStatus != null &&
        profile.civilStatus!.trim().isNotEmpty)
      FactRowData(
        icon: Icons.people,
        label: 'Civil status',
        value: ProfileHelpers.toTitleCase(
          profile.civilStatus!.replaceAll('_', ' '),
        ),
      ),
    if (profile.religion != null && profile.religion!.trim().isNotEmpty)
      FactRowData(
        icon: Icons.favorite,
        label: 'Religion',
        value: profile.religion!.trim(),
      ),
    if (profile.maritalStatus != null &&
        profile.maritalStatus!.trim().isNotEmpty)
      FactRowData(
        icon: Icons.people,
        label: 'Marital status',
        value: ProfileHelpers.toTitleCase(
          profile.maritalStatus!.replaceAll('_', ' '),
        ),
      ),
    if (profile.languages.isNotEmpty)
      FactRowData(
        icon: Icons.translate,
        label: 'Languages',
        value: profile.languages.join(', '),
      ),
    if (profile.numberOfChildren != null)
      FactRowData(
        icon: Icons.people,
        label: 'Children',
        value: '${profile.numberOfChildren}',
      ),
  ];
}

/// Builds completion tip list.
List<CompletionTipData> buildCompletionTips({
  required BuildContext context,
  required bool hasBio,
  required int photoCount,
  required int interestCount,
  required bool hasGender,
}) {
  return [
    if (!hasBio)
      CompletionTipData(
        label: 'Write a short introduction',
        actionLabel: 'Add bio',
        boost: '+20%',
        onTap: () => _openEditFromContext(context),
      ),
    if (photoCount < minPhotosForBonus)
      CompletionTipData(
        label: 'Add more photos',
        actionLabel: 'Upload',
        boost: '+20%',
        onTap: () => _openPhotosFromContext(context),
      ),
    if (interestCount < minInterestsForCompletion)
      CompletionTipData(
        label: 'Add interests',
        actionLabel: 'Choose',
        boost: '+15%',
        onTap: () => _openEditFromContext(context),
      ),
    if (!hasGender)
      CompletionTipData(
        label: 'Complete the basics',
        actionLabel: 'Update',
        boost: '+10%',
        onTap: () => _openEditFromContext(context),
      ),
  ];
}

void _openEditFromContext(BuildContext context) {
  _showSheet(context, const ProfileEditScreen());
}

void _openPhotosFromContext(BuildContext context) {
  _showSheet(context, const ProfilePhotosScreen());
}

void _showSheet(BuildContext context, Widget child) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withAlpha(100),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: FractionallySizedBox(heightFactor: 0.92, child: child),
      ),
    ),
    transitionBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

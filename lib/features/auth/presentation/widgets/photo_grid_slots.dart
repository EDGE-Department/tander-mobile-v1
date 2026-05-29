import 'dart:io';

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ---------------------------------------------------------------------------
// Photo slot model
// ---------------------------------------------------------------------------

/// Immutable snapshot of one photo slot in the upload grid.
///
/// [id] is a stable, monotonically-increasing identity assigned at add-time.
/// Upload write-back and removal MUST match on [id] (not positional index),
/// because removing an earlier slot contracts the list and shifts indices —
/// which previously stranded a slot mid-upload or wrote the result to the
/// wrong slot.
class PhotoSlot {
  const PhotoSlot({
    required this.id,
    required this.file,
    required this.isUploaded,
    required this.isUploading,
  });

  final int id;
  final File file;
  final bool isUploaded;
  final bool isUploading;

  PhotoSlot copyWith({bool? isUploaded, bool? isUploading}) {
    return PhotoSlot(
      id: id,
      file: file,
      isUploaded: isUploaded ?? this.isUploaded,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

// ---------------------------------------------------------------------------
// Filled slot widget — displays an uploaded or uploading photo
// ---------------------------------------------------------------------------

class FilledPhotoSlot extends StatelessWidget {
  const FilledPhotoSlot({
    required this.slot,
    required this.index,
    required this.onRemove,
    super.key,
  });

  final PhotoSlot slot;
  final int index;
  final VoidCallback onRemove;

  bool get _isMain => index == 0;

  @override
  Widget build(BuildContext context) {
    final Widget slotStack = ClipRRect(
      borderRadius: AppRadius.borderLg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(slot.file, fit: BoxFit.cover),
          if (slot.isUploading) _buildUploadingOverlay(),
          if (_isMain && slot.isUploaded) _buildMainBadge(),
          if (!_isMain && slot.isUploaded) _buildUploadedCheckmark(),
          _buildRemoveButton(),
        ],
      ),
    );

    // While uploading, the overlay carries its own live "Uploading photo"
    // announcement. Once settled, label the slot as added so screen-reader
    // users know what each tile holds (the main/profile photo is called out).
    if (slot.isUploading) {
      return slotStack;
    }
    return Semantics(
      image: true,
      label: _isMain ? 'Main photo added' : 'Photo added',
      child: slotStack,
    );
  }

  Widget _buildUploadingOverlay() {
    return Semantics(
      label: 'Uploading photo',
      liveRegion: true,
      child: Container(
        color: AppColors.overlay,
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainBadge() {
    return Positioned(
      top: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.borderFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 12,
              color: AppColors.textInverse,
            ),
            const SizedBox(width: 2),
            Text(
              'Main',
              style: AppTypography.caption.copyWith(
                color: AppColors.textInverse,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedCheckmark() {
    return Positioned(
      top: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: AppShadows.warmXs,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: AppColors.textInverse,
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    // The visible affordance is a 32px circle, but the HIT AREA must be >=44px
    // (WCAG 2.2 / elder-friendly). We center the 32px circle inside a 44px
    // opaque gesture region. The 6px centering inset is offset by positioning
    // the region 2px from the edge so the visible circle keeps its original
    // ~8px corner inset.
    return Positioned(
      top: 2,
      right: 2,
      child: Semantics(
        button: true,
        label: 'Remove photo',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRemove,
          child: SizedBox(
            width: AppSpacing.touchMinimum,
            height: AppSpacing.touchMinimum,
            child: Center(
              child: Container(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                decoration: const BoxDecoration(
                  color: AppColors.overlay,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textInverse,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty slot widget — dashed-border placeholder for adding photos
// ---------------------------------------------------------------------------

class EmptyPhotoSlot extends StatelessWidget {
  const EmptyPhotoSlot({required this.isFirst, required this.onTap, super.key});

  final bool isFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFirst ? 'Add main photo' : 'Add photo',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isFirst ? AppColors.primaryLight : AppColors.subtle,
            borderRadius: AppRadius.borderLg,
            border: Border.all(
              color: isFirst
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.primary : AppColors.border,
                  borderRadius: AppRadius.borderMd,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: isFirst ? AppColors.textInverse : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isFirst ? 'Main photo' : 'Add Photo',
                style: AppTypography.caption.copyWith(
                  color: isFirst ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

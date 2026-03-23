/// Uniform 3-column photo grid for the profile screen.
///
/// Shows existing photos with tap-to-view and an "add" slot when below
/// the maximum count. Extracted from profile_page_components to keep
/// each file under 400 lines.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';

/// Photo grid displaying profile images with optional add-photo slot.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({
    required this.gallery,
    required this.maxPhotoCount,
    required this.onPhotoTap,
    required this.onAddPhoto,
    super.key,
  });

  final List<String> gallery;
  final int maxPhotoCount;
  final ValueChanged<int> onPhotoTap;
  final VoidCallback onAddPhoto;

  static const int _columnCount = 3;

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) {
      return EmptyPrompt(
        text: 'Add a clear portrait and a few supporting photos so people '
            'can recognize you and get a better sense of your life.',
        actionLabel: 'Upload photos',
        onAction: onAddPhoto,
      );
    }

    final bool canAddMore = gallery.length < maxPhotoCount;
    final int itemCount = gallery.length + (canAddMore ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columnCount,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < gallery.length) {
          return _PhotoTile(
            url: gallery[index],
            index: index,
            onTap: () => onPhotoTap(index),
          );
        }
        return _AddPhotoTile(onTap: onAddPhoto);
      },
    );
  }
}

// ── Photo tile ───────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.url,
    required this.index,
    required this.onTap,
  });

  final String url;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.subtle),
              errorWidget: (_, _, _) => Container(
                color: AppColors.subtle,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            if (index == 0)
              Positioned(
                bottom: AppSpacing.xs,
                left: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: AppRadius.borderFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt, size: 10, color: AppColors.textInverse),
                      const SizedBox(width: 3),
                      Text(
                        'Main',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Add photo tile ───────────────────────────────────────────────────────

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: AppColors.border,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 22, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Add photo',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial gallery layout for the profile screen.
///
/// Uses one large featured photo, a compact side stack, and a smaller
/// supporting grid so the section feels intentional rather than uniform.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/shared/utils/photo_url.dart';

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

  @override
  Widget build(BuildContext context) {
    if (gallery.isEmpty) {
      return EmptyPrompt(
        text:
            'Add a clear portrait and a few supporting photos so people '
            'can recognize you and get a better sense of your life.',
        actionLabel: 'Upload photos',
        onAction: onAddPhoto,
      );
    }

    final featuredPhoto = gallery.first;
    final railPhotos = gallery.skip(1).take(2).toList(growable: false);
    final extraPhotos = gallery.skip(3).toList(growable: false);
    final int remainingSlots =
        (maxPhotoCount - gallery.length).clamp(0, maxPhotoCount) as int;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 560;
        final double trailingWidth = isWide
            ? (constraints.maxWidth - AppSpacing.sm) * 0.37
            : constraints.maxWidth;
        final int trailingColumns = isWide ? 3 : 2;
        final double tileWidth =
            (trailingWidth - (AppSpacing.sm * (trailingColumns - 1))) /
            trailingColumns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 8,
                    child: _GalleryTile(
                      url: featuredPhoto,
                      label: 'Featured',
                      subtitle: 'Main profile photo',
                      badgeTone: _GalleryBadgeTone.featured,
                      onTap: () => onPhotoTap(0),
                      aspectRatio: 0.82,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: trailingWidth,
                    child: Column(
                      children: [
                        for (
                          int index = 0;
                          index < railPhotos.length;
                          index++
                        ) ...[
                          _GalleryTile(
                            url: railPhotos[index],
                            label: 'Moment ${index + 2}',
                            subtitle: index == 0
                                ? 'Warm introduction'
                                : 'Another highlight',
                            onTap: () => onPhotoTap(index + 1),
                            aspectRatio: 1.0,
                          ),
                          if (index < railPhotos.length - 1)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                        if (railPhotos.length < 2 && remainingSlots > 0) ...[
                          if (railPhotos.isNotEmpty)
                            const SizedBox(height: AppSpacing.sm),
                          _AddPhotoTile(compact: true, onTap: onAddPhoto),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _GalleryTile(
                url: featuredPhoto,
                label: 'Featured',
                subtitle: 'Main profile photo',
                badgeTone: _GalleryBadgeTone.featured,
                onTap: () => onPhotoTap(0),
                aspectRatio: 1.02,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (railPhotos.isNotEmpty || remainingSlots > 0)
                Row(
                  children: [
                    for (int index = 0; index < railPhotos.length; index++) ...[
                      Expanded(
                        child: _GalleryTile(
                          url: railPhotos[index],
                          label: 'Moment ${index + 2}',
                          subtitle: 'Profile highlight',
                          onTap: () => onPhotoTap(index + 1),
                          compact: true,
                          aspectRatio: 1.0,
                        ),
                      ),
                      if (index < railPhotos.length - 1)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                    if (railPhotos.length < 2 && remainingSlots > 0) ...[
                      if (railPhotos.isNotEmpty)
                        const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _AddPhotoTile(onTap: onAddPhoto)),
                    ],
                  ],
                ),
            ],
            if (extraPhotos.isNotEmpty ||
                remainingSlots > (railPhotos.length < 2 ? 1 : 0)) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (int index = 0; index < extraPhotos.length; index++)
                    SizedBox(
                      width: tileWidth,
                      child: _GalleryTile(
                        url: extraPhotos[index],
                        label: 'Photo ${index + 4}',
                        subtitle: 'Gallery detail',
                        onTap: () => onPhotoTap(index + 3),
                        compact: true,
                        aspectRatio: 1.0,
                      ),
                    ),
                  if (remainingSlots > (railPhotos.length < 2 ? 1 : 0))
                    SizedBox(
                      width: tileWidth,
                      child: _AddPhotoTile(onTap: onAddPhoto),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

enum _GalleryBadgeTone { defaultTone, featured }

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.url,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.aspectRatio = 1,
    this.compact = false,
    this.badgeTone = _GalleryBadgeTone.defaultTone,
  });

  final String url;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final double aspectRatio;
  final bool compact;
  final _GalleryBadgeTone badgeTone;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.warmLg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    resolvePhotoUrl(url) ?? url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.subtle,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x1AFFFFFF),
                          Color(0x00000000),
                          Color(0xAA120B06),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _GalleryBadge(label: label, tone: badgeTone),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!compact)
                                Text(
                                  'SHOWCASE',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white.withValues(alpha: 0.74),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              if (!compact) const SizedBox(height: 4),
                              Text(
                                label,
                                style:
                                    (compact
                                            ? AppTypography.h3
                                            : AppTypography.h2)
                                        .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: AppTypography.bodySm.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: AppRadius.borderFull,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryBadge extends StatelessWidget {
  const _GalleryBadge({required this.label, required this.tone});

  final String label;
  final _GalleryBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final bool featured = tone == _GalleryBadgeTone.featured;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: featured
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.borderFull,
        border: featured
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            featured ? Icons.star_rounded : Icons.photo_library_outlined,
            size: 12,
            color: featured ? AppColors.primaryAccessible : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: featured ? AppColors.primaryAccessible : Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.24),
                style: BorderStyle.solid,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF8EF), Color(0xFFFFF1E4)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.0,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.warmMd,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'ADD PHOTO',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryAccessible,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          compact
                              ? 'Fill this spot'
                              : 'Give your gallery more personality',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

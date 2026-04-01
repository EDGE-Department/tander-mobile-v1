/// Photo management screen for the user's profile.
///
/// Displays a 3-column grid of up to 6 photo slots. Filled slots show
/// the image with a "Main" badge on slot 0 and a remove button.
/// Empty slots offer an add-photo action via [image_picker].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/notifiers/my_profile_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/states/profile_state.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_bottom_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Maximum number of photos a user can have.
const int _maxPhotoSlots = 6;

/// Column count for the photo grid.
const int _gridColumnCount = 3;

/// Photo management screen.
class ProfilePhotosScreen extends ConsumerStatefulWidget {
  const ProfilePhotosScreen({super.key});

  @override
  ConsumerState<ProfilePhotosScreen> createState() =>
      _ProfilePhotosScreenState();
}

class _ProfilePhotosScreenState extends ConsumerState<ProfilePhotosScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  List<String> _buildPhotoList() {
    final profileState = ref.watch(myProfileNotifierProvider);
    if (profileState is! ProfileLoaded) return [];
    return ProfileHelpers.buildGallery(profileState.profile);
  }

  Future<void> _handleAddPhoto(int slotIndex) async {
    final source = await _showSourcePicker();
    if (source == null || !mounted) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile == null || !mounted) return;

    setState(() => _isUploading = true);

    final isMainPhoto = slotIndex == 0 && _buildPhotoList().isEmpty;
    bool didSucceed;

    if (isMainPhoto) {
      didSucceed = await ref
          .read(myProfileNotifierProvider.notifier)
          .uploadProfilePhoto(pickedFile.path);
    } else {
      didSucceed = await ref
          .read(myProfileNotifierProvider.notifier)
          .uploadAdditionalPhotos([pickedFile.path]);
    }

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (didSucceed) {
      TanderToastOverlay.show(
        context,
        const TanderToastData(
          message: 'Photo uploaded successfully.',
          variant: TanderToastVariant.success,
        ),
      );
    } else {
      TanderToastOverlay.show(
        context,
        const TanderToastData(
          message: 'Upload failed. Please try a different image.',
          variant: TanderToastVariant.error,
        ),
      );
    }
  }

  Future<ImageSource?> _showSourcePicker() async {
    return TanderBottomSheet.show<ImageSource>(
      context: context,
      title: 'Add photo',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SourceOption(
              icon: Icons.camera_alt,
              label: 'Take a photo',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.xs),
            _SourceOption(
              icon: Icons.photo_library,
              label: 'Choose from gallery',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleReorder(List<String> newOrder) async {
    await ref
        .read(myProfileNotifierProvider.notifier)
        .reorderPhotos(newOrder);
  }

  Future<void> _handleRemovePhoto(int galleryIndex) async {
    final didSucceed = await ref
        .read(myProfileNotifierProvider.notifier)
        .deletePhoto(galleryIndex);

    if (!mounted) return;

    if (didSucceed) {
      TanderToastOverlay.show(
        context,
        const TanderToastData(
          message: 'Photo removed.',
          variant: TanderToastVariant.success,
        ),
      );
    } else {
      TanderToastOverlay.show(
        context,
        const TanderToastData(
          message: 'Failed to remove photo. Please try again.',
          variant: TanderToastVariant.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _buildPhotoList();
    final photoCount = photos.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to profile',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Photos', style: AppTypography.h3),
            Text(
              '$photoCount/$_maxPhotoSlots photos added',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your first photo is your main profile photo. Long-press to drag and reorder. You can have up to $_maxPhotoSlots photos.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            _DraggablePhotoGrid(
              photos: photos,
              isUploading: _isUploading,
              onAddPhoto: _handleAddPhoto,
              onRemovePhoto: _handleRemovePhoto,
              onReorder: _handleReorder,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Draggable photo grid ─────────────────────────────────────────────────

class _DraggablePhotoGrid extends StatefulWidget {
  const _DraggablePhotoGrid({
    required this.photos,
    required this.isUploading,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onReorder,
  });

  final List<String> photos;
  final bool isUploading;
  final ValueChanged<int> onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final ValueChanged<List<String>> onReorder;

  @override
  State<_DraggablePhotoGrid> createState() => _DraggablePhotoGridState();
}

class _DraggablePhotoGridState extends State<_DraggablePhotoGrid> {
  int? _dragOverIndex;

  void _handleAccept(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    final reordered = List<String>.from(widget.photos);
    final moved = reordered.removeAt(fromIndex);
    reordered.insert(toIndex, moved);
    widget.onReorder(reordered);
    setState(() => _dragOverIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final bool canAddMore = widget.photos.length < _maxPhotoSlots;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final gap = screenWidth >= 640 ? 10.0 : 8.0;
    final gridWidth = screenWidth - AppSpacing.md * 2;
    final cellSize = (gridWidth - gap * (_gridColumnCount - 1)) / _gridColumnCount;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        // Photo tiles with drag support
        for (int index = 0; index < widget.photos.length; index++)
          _DraggablePhotoTile(
            index: index,
            photoUrl: widget.photos[index],
            isMain: index == 0,
            cellSize: cellSize,
            isDragOver: _dragOverIndex == index,
            onRemove: () => widget.onRemovePhoto(index),
            onDragStarted: () => setState(() {}),
            onDragOver: () => setState(() => _dragOverIndex = index),
            onDragEnd: () => setState(() => _dragOverIndex = null),
            onAccept: (fromIndex) => _handleAccept(fromIndex, index),
          ),

        // Add photo slot
        if (canAddMore)
          SizedBox(
            width: cellSize,
            height: cellSize,
            child: _EmptySlot(
              isUploading: widget.isUploading,
              onTap: () => widget.onAddPhoto(widget.photos.length),
            ),
          ),
      ],
    );
  }
}

class _DraggablePhotoTile extends StatelessWidget {
  const _DraggablePhotoTile({
    required this.index,
    required this.photoUrl,
    required this.isMain,
    required this.cellSize,
    required this.isDragOver,
    required this.onRemove,
    required this.onDragStarted,
    required this.onDragOver,
    required this.onDragEnd,
    required this.onAccept,
  });

  final int index;
  final String photoUrl;
  final bool isMain;
  final double cellSize;
  final bool isDragOver;
  final VoidCallback onRemove;
  final VoidCallback onDragStarted;
  final VoidCallback onDragOver;
  final VoidCallback onDragEnd;
  final ValueChanged<int> onAccept;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: cellSize,
      height: cellSize,
      child: _FilledSlot(
        photoUrl: photoUrl,
        isMain: isMain,
        onRemove: onRemove,
        showDragHandle: true,
      ),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (details.data != index) onDragOver();
        return details.data != index;
      },
      onAcceptWithDetails: (details) => onAccept(details.data),
      onLeave: (_) => onDragEnd(),
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<int>(
          data: index,
          onDragStarted: onDragStarted,
          onDragEnd: (_) => onDragEnd(),
          feedback: Material(
            elevation: 8,
            borderRadius: AppRadius.borderLg,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: cellSize,
              height: cellSize,
              child: Opacity(
                opacity: 0.85,
                child: Image.network(photoUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          childWhenDragging: SizedBox(
            width: cellSize,
            height: cellSize,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: isDragOver
                ? BoxDecoration(
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  )
                : null,
            child: child,
          ),
        );
      },
    );
  }
}

// ── Filled photo slot ───────────────────────────────────────────────────

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({required this.photoUrl, required this.isMain, required this.onRemove, this.showDragHandle = false});
  final String photoUrl;
  final bool isMain;
  final VoidCallback onRemove;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Photo with rounded corners
        Positioned.fill(
          child: ClipRRect(
            borderRadius: AppRadius.borderLg,
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.subtle,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        // Drag handle
        if (showDragHandle)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.drag_indicator, size: 14, color: AppColors.textInverse),
            ),
          ),
        // "Main" badge
        if (isMain)
          Positioned(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.borderFull),
              child: Text('Main', style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textInverse)),
            ),
          ),
        // Delete button — outside ClipRRect so it's never clipped
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.delete_outline, size: 13, color: AppColors.textInverse),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty photo slot ────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.isUploading, required this.onTap});
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: AppRadius.borderLg, border: Border.all(color: AppColors.border, width: 2, strokeAlign: BorderSide.strokeAlignInside)),
        child: isUploading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add, size: 24, color: AppColors.textMuted),
                const SizedBox(height: AppSpacing.xxs),
                Text('Add Photo', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              ]),
      ),
    );
  }
}

// ── Source picker option ────────────────────────────────────────────────

class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card, borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap, borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: AppRadius.borderLg),
          child: Row(children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.label),
          ]),
        ),
      ),
    );
  }
}

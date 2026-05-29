/// Bottom sheet for creating a new community post — text area + photo picker
/// grid (max 4 photos) + post button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/community/presentation/providers/community_providers.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

/// Maximum number of photos allowed per post.
const int _maxPhotos = 4;

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({required this.onPostCreated, super.key});

  final VoidCallback onPostCreated;

  /// Present the create-post UI.
  /// Mobile (<768): bottom sheet matching web's SlideUpSheet.
  /// Tablet/desktop (>=768): centered dialog.
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onPostCreated,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth >= 768) {
      return _showAsDialog(context: context, onPostCreated: onPostCreated);
    }
    return _showAsSheet(
      context: context,
      ref: ref,
      onPostCreated: onPostCreated,
    );
  }

  static Future<void> _showAsSheet({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onPostCreated,
  }) {
    ref.read(modalVisibleProvider.notifier).state = true;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: X + "New post" + Post button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'New post',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Post button placeholder — actual submit is inside CreatePostSheet
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              CreatePostSheet(onPostCreated: onPostCreated),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      ref.read(modalVisibleProvider.notifier).state = false;
    });
  }

  static Future<void> _showAsDialog({
    required BuildContext context,
    required VoidCallback onPostCreated,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            surfaceTintColor: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      Text('New Post', style: AppTypography.h3),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(child: CreatePostSheet(onPostCreated: onPostCreated)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedPhotos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_isSubmitting && _textController.text.trim().isNotEmpty;

  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= _maxPhotos) return;

    final List<XFile> picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    if (picked.isEmpty) return;

    setState(() {
      final remaining = _maxPhotos - _selectedPhotos.length;
      _selectedPhotos.addAll(picked.take(remaining));
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final photoPaths = _selectedPhotos.map((file) => file.path).toList();

    final repository = ref.read(communityRepositoryProvider);
    final createResult = await repository.createPost(
      content: content,
      photoPaths: photoPaths,
    );

    if (!mounted) return;

    createResult.when(
      success: (_) {
        widget.onPostCreated();
        Navigator.of(context).pop();
      },
      failure: (exception) {
        setState(() => _isSubmitting = false);
        AppLogger.error(
          'Failed to create post',
          operation: 'CreatePostSheet',
          error: exception,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.userMessage),
            backgroundColor: AppColors.danger,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Text input.
          TextField(
            controller: _textController,
            maxLines: 6,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What would you like to share?',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.subtle,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Photo picker row.
          _PhotoPickerRow(
            photos: _selectedPhotos,
            onPickPhoto: _pickPhoto,
            onRemovePhoto: _removePhoto,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Submit button.
          ListenableBuilder(
            listenable: _textController,
            builder: (context, _) {
              return TanderButton(
                label: 'Post',
                onPressed: _canSubmit ? _submitPost : null,
                isLoading: _isSubmitting,
                icon: Icons.send_rounded,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Photo picker row ───────────────────────────────────────────────────

class _PhotoPickerRow extends StatelessWidget {
  const _PhotoPickerRow({
    required this.photos,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final List<XFile> photos;
  final VoidCallback onPickPhoto;
  final void Function(int index) onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos',
              style: AppTypography.label.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('${photos.length}/$_maxPhotos', style: AppTypography.caption),
            const Spacer(),
            if (photos.length < _maxPhotos)
              GestureDetector(
                onTap: onPickPhoto,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.borderFull,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                return _PhotoThumbnail(
                  file: photos[index],
                  onRemove: () => onRemovePhoto(index),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: AppRadius.borderMd,
          child: Image.asset(
            file.path,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 80,
              height: 80,
              color: AppColors.subtle,
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

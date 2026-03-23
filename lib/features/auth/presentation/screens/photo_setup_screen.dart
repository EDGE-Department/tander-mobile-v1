import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/onboarding_chrome.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/photo_grid_slots.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_bottom_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

// ---------------------------------------------------------------------------
// Constants — matches web: 4-slot grid (2x2), 5 MB limit
// ---------------------------------------------------------------------------

const int _maxPhotos = 4;
const int _gridCrossAxisCount = 2;
const int _maxFileSizeBytes = 5 * 1024 * 1024;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Onboarding step 2 of 3 — photo upload grid (2x2, up to 4 slots).
///
/// Matches the web photo-setup-page.tsx mobile layout: step badge, heading,
/// 2x2 grid with filled/empty slots, privacy note, continue/skip buttons.
/// Requires at least 1 photo to continue. Uploads via multipart POST.
class PhotoSetupScreen extends ConsumerStatefulWidget {
  const PhotoSetupScreen({super.key});

  @override
  ConsumerState<PhotoSetupScreen> createState() => _PhotoSetupScreenState();
}

class _PhotoSetupScreenState extends ConsumerState<PhotoSetupScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<PhotoSlot> _slots = [];
  String? _errorMessage;

  bool get _hasAtLeastOnePhoto => _slots.isNotEmpty;
  bool get _allUploaded =>
      _slots.isNotEmpty && _slots.every((slot) => slot.isUploaded);
  bool get _canContinue => _hasAtLeastOnePhoto && _allUploaded;

  // -- Image picking --------------------------------------------------------

  Future<void> _showImageSourcePicker() async {
    if (_slots.length >= _maxPhotos) {
      _setError('You can add up to $_maxPhotos photos.');
      return;
    }

    await TanderBottomSheet.show<void>(
      context: context,
      title: 'Add Photo',
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a photo',
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.subtle,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > _maxFileSizeBytes) {
        _setError('Each photo must be under 5 MB.');
        return;
      }
      if (_slots.length >= _maxPhotos) {
        _setError('You can add up to $_maxPhotos photos.');
        return;
      }

      _setError(null);
      final slotIndex = _slots.length;
      setState(() {
        _slots
            .add(PhotoSlot(file: file, isUploaded: false, isUploading: true));
      });
      await _uploadPhoto(file, slotIndex);
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Image picking failed',
        operation: 'PhotoSetupScreen._pickImage',
        error: error,
        stackTrace: stackTrace,
      );
      _setError('Failed to pick image. Please try again.');
    }
  }

  // -- Upload ---------------------------------------------------------------

  Future<void> _uploadPhoto(File file, int slotIndex) async {
    try {
      final dioClient = ref.read(dioClientProvider);
      final endpoint = slotIndex == 0
          ? ApiEndpoints.uploadProfilePhoto
          : ApiEndpoints.uploadAdditionalPhotos;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      await dioClient.post<Map<String, Object?>>(endpoint, data: formData);

      if (mounted && slotIndex < _slots.length) {
        setState(() {
          _slots[slotIndex] =
              _slots[slotIndex].copyWith(isUploaded: true, isUploading: false);
        });
      }
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Photo upload failed',
        operation: 'PhotoSetupScreen._uploadPhoto',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted && slotIndex < _slots.length) {
        setState(() => _slots.removeAt(slotIndex));
        _setError('Upload failed. Please try again.');
      }
    }
  }

  // -- Remove & navigate ----------------------------------------------------

  void _removeSlot(int index) {
    if (index >= _slots.length) return;
    setState(() {
      _slots.removeAt(index);
      _errorMessage = null;
    });
  }

  Future<void> _onContinue() async {
    if (!_canContinue) return;
    await ref.read(authNotifierProvider.notifier).refreshSession();
    if (mounted) context.go(AppRoutes.notificationPermission);
  }

  void _onSkip() => context.go(AppRoutes.notificationPermission);

  void _setError(String? message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: onboardingGradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnboardingStepBadge(currentStep: 2),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeading(),
                    const SizedBox(height: AppSpacing.lg),
                    if (_errorMessage != null) ...[
                      OnboardingErrorBanner(message: _errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildPhotoGrid(),
                    const SizedBox(height: AppSpacing.md),
                    _buildPrivacyNote(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContinueButton(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSkipButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Add Your Photos',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Your first photo is your profile picture',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridCrossAxisCount,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: _maxPhotos,
      itemBuilder: (context, index) {
        if (index < _slots.length) {
          return FilledPhotoSlot(
            slot: _slots[index],
            index: index,
            onRemove: () => _removeSlot(index),
          );
        }
        return EmptyPhotoSlot(
          isFirst: index == 0 && _slots.isEmpty,
          onTap: _showImageSourcePicker,
        );
      },
    );
  }

  Widget _buildPrivacyNote() {
    return Text(
      'Your photos are only visible to verified members.',
      style: AppTypography.caption,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildContinueButton() {
    if (!_hasAtLeastOnePhoto) {
      return const TanderButton(
        label: 'Add at least 1 photo to continue',
        onPressed: null,
        variant: TanderButtonVariant.outline,
        isDisabled: true,
        icon: Icons.photo_library_rounded,
      );
    }
    if (!_allUploaded) {
      return const TanderButton(
        label: 'Uploading...',
        onPressed: null,
        variant: TanderButtonVariant.outline,
        isLoading: true,
      );
    }
    return TanderButton(
      label: 'Complete setup',
      onPressed: _onContinue,
      icon: Icons.arrow_forward_rounded,
      iconPosition: IconPosition.trailing,
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: GestureDetector(
        onTap: _onSkip,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            "I'll add photos later",
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

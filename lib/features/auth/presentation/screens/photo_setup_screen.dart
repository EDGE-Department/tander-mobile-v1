import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_error_display.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_success_confirmation.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/photo_grid_slots.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/registration_step_dots.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_bottom_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

const int _maxPhotos = 4;
const int _gridCrossAxisCount = 2;
const int _maxFileSizeBytes = 5 * 1024 * 1024;

/// Onboarding step 4 of 4 — photo upload grid.
///
/// Matches sign-up design: gradient bg + constellation header + white sheet.
class PhotoSetupScreen extends ConsumerStatefulWidget {
  const PhotoSetupScreen({super.key});

  @override
  ConsumerState<PhotoSetupScreen> createState() => _PhotoSetupScreenState();
}

class _PhotoSetupScreenState extends ConsumerState<PhotoSetupScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final List<PhotoSlot> _slots = [];
  String? _errorMessage;
  NetworkException? _offlineError;
  // Last failed upload file, retained for the retry CTA.
  File? _lastUploadFile;
  // Monotonically-increasing identity assigned to each slot at add-time so
  // upload write-back and removal MATCH ON ID, never positional index. A
  // removal that contracts the list must not strand an in-flight slot or
  // write an upload result to the wrong slot.
  int _nextSlotId = 0;

  @override
  void dispose() {
    // Best-effort cleanup of image_picker temp files we still hold so they do
    // not accumulate in the cache directory. Ignore failures.
    final seen = <String>{};
    for (final slot in _slots) {
      if (seen.add(slot.file.path)) _deleteTempFile(slot.file);
    }
    super.dispose();
  }

  /// Best-effort deletes the temp file backing a removed slot, but only when
  /// no remaining slot still references the same path.
  void _deleteTempFileIfUnreferenced(File file) {
    final stillReferenced = _slots.any((slot) => slot.file.path == file.path);
    if (stillReferenced) return;
    _deleteTempFile(file);
  }

  /// Best-effort, exception-swallowing delete of an image_picker temp file.
  void _deleteTempFile(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Temp photo cleanup failed',
        operation: 'PhotoSetupScreen._deleteTempFile',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool get _hasAtLeastOnePhoto => _slots.isNotEmpty;
  bool get _allUploaded =>
      _slots.isNotEmpty && _slots.every((slot) => slot.isUploaded);
  bool get _anyUploadInFlight => _slots.any((slot) => slot.isUploading);
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
      // The first photo in the grid is the profile/main photo and uses a
      // different endpoint. Decide that from the current position at add-time.
      final isMain = _slots.isEmpty;
      final slotId = _nextSlotId++;
      setState(() {
        _slots.add(
          PhotoSlot(
            id: slotId,
            file: file,
            isUploaded: false,
            isUploading: true,
          ),
        );
      });
      await _uploadPhoto(file, slotId, isMain: isMain);
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

  Future<void> _uploadPhoto(
    File file,
    int slotId, {
    required bool isMain,
  }) async {
    if (mounted) setState(() => _offlineError = null);
    try {
      final dioClient = ref.read(dioClientProvider);
      final endpoint = isMain
          ? ApiEndpoints.uploadProfilePhoto
          : ApiEndpoints.uploadAdditionalPhotos;

      // Field name must match the backend's @RequestParam binding per endpoint:
      // /upload-profile-photo binds "profilePhoto" (single); /upload-additional-photos
      // binds "additionalPhotos" (List, but a single part binds as a 1-element list).
      // The old shared 'file' name bound to neither -> hard 500 on every onboarding photo.
      final fieldName = isMain ? 'profilePhoto' : 'additionalPhotos';
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      await dioClient.post<Map<String, Object?>>(endpoint, data: formData);

      // Write the result back to the slot that still carries this id. The
      // slot may have shifted position (or been removed) while in flight.
      if (mounted) {
        final i = _slots.indexWhere((slot) => slot.id == slotId);
        if (i != -1) {
          setState(() {
            _slots[i] = _slots[i].copyWith(
              isUploaded: true,
              isUploading: false,
            );
          });
        }
      }
    } on DioException catch (error, stackTrace) {
      // Catch ordering policy — see network_exception_handler.dart.
      AppLogger.error(
        'Photo upload failed',
        operation: 'PhotoSetupScreen._uploadPhoto',
        error: error,
        stackTrace: stackTrace,
      );
      if (error.response?.statusCode == 401) {
        _removeSlotById(slotId);
        if (mounted) {
          TanderToastOverlay.show(
            context,
            const TanderToastData(
              message: 'Session expired. Please sign in again.',
              variant: TanderToastVariant.error,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.go(AppRoutes.login);
        }
        return;
      }
      // Only surface the failure if the slot is still present — if the user
      // already removed it mid-flight, stay silent.
      if (_removeSlotById(slotId)) {
        _setError('Upload failed. Please try again.');
      }
    } on NetworkException catch (error, stackTrace) {
      AppLogger.error(
        'Photo upload failed (offline)',
        operation: 'PhotoSetupScreen._uploadPhoto',
        error: error,
        stackTrace: stackTrace,
      );
      // Retain the file for the retry CTA, so do NOT delete its temp file here.
      // Only arm the retry banner if the user hasn't already removed the slot.
      final wasPresent = _removeSlotById(slotId, deleteTempFile: false);
      if (wasPresent && mounted) {
        setState(() {
          _offlineError = error;
          _lastUploadFile = file;
        });
      } else {
        // Slot gone (user removed it mid-flight) — drop the retained file so
        // it doesn't leak, unless another slot still references the same path.
        _deleteTempFileIfUnreferenced(file);
      }
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Photo upload failed',
        operation: 'PhotoSetupScreen._uploadPhoto',
        error: error,
        stackTrace: stackTrace,
      );
      if (_removeSlotById(slotId)) {
        _setError('Upload failed. Please try again.');
      }
    }
  }

  Future<void> _retryUpload() async {
    final file = _lastUploadFile;
    if (file == null) return;
    final isMain = _slots.isEmpty;
    final slotId = _nextSlotId++;
    setState(() {
      _offlineError = null;
      _slots.add(
        PhotoSlot(
          id: slotId,
          file: file,
          isUploaded: false,
          isUploading: true,
        ),
      );
    });
    await _uploadPhoto(file, slotId, isMain: isMain);
  }

  // -- Remove & navigate ----------------------------------------------------

  /// Removes the slot at [index] (user-initiated, from the grid). The slot's
  /// temp file is deleted best-effort if no other slot references it.
  void _removeSlot(int index) {
    if (index < 0 || index >= _slots.length) return;
    final removed = _slots[index];
    setState(() {
      _slots.removeAt(index);
      _errorMessage = null;
    });
    _deleteTempFileIfUnreferenced(removed.file);
  }

  /// Removes the slot carrying [slotId] regardless of its current position.
  /// Used by upload-failure handlers, where the slot may have shifted while
  /// the request was in flight. Set [deleteTempFile] false to retain the file
  /// for a retry CTA. Returns true only if a slot was actually removed — the
  /// caller should suppress failure messaging when the user already removed
  /// the slot mid-flight (false), so we don't alarm them about a photo they
  /// deliberately discarded.
  bool _removeSlotById(int slotId, {bool deleteTempFile = true}) {
    final index = _slots.indexWhere((slot) => slot.id == slotId);
    if (index == -1) return false;
    final removed = _slots[index];
    if (mounted) {
      setState(() => _slots.removeAt(index));
    } else {
      _slots.removeAt(index);
    }
    if (deleteTempFile) _deleteTempFileIfUnreferenced(removed.file);
    return true;
  }

  Future<void> _onContinue() async {
    if (!_canContinue) return;
    await ref.read(authNotifierProvider.notifier).refreshSession();
    if (!mounted) return;
    await AuthSuccessConfirmation.show(context, 'Photos uploaded!');
    if (mounted) context.go(AppRoutes.discover);
  }

  Future<void> _onSkip() async {
    // Refresh session before navigating so the router sees the updated
    // registrationPhase from the backend (profile-setup PUT advances it
    // to COMPLETE). Without this the cached PENDING_PROFILE_SETUP phase
    // makes the router bounce the user back to onboarding.
    await ref.read(authNotifierProvider.notifier).refreshSession();
    if (mounted) context.go(AppRoutes.discover);
  }

  void _setError(String? message) {
    if (mounted) setState(() => _errorMessage = message);
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = resolveHeaderHeight(screenHeight);

    return PopScope(
      canPop: !_anyUploadInFlight,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          TanderToastOverlay.show(
            context,
            const TanderToastData(
              message: 'Please wait for uploads to complete.',
              variant: TanderToastVariant.info,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF20BF68),
        body: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: authGradient),
                ),
              ),
            ),
            Column(
              children: [
                _buildHeader(headerHeight),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -8),
                    child: _buildWhiteSheet(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double headerHeight) {
    final horizontalOverscan = MediaQuery.sizeOf(context).width * 0.10;
    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -horizontalOverscan,
            right: -horizontalOverscan,
            top: 0,
            bottom: 0,
            child: const IgnorePointer(child: AuthHeaderScene()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Column(
                children: [
                  _buildNavRow(),
                  const Spacer(),
                  Image.asset(
                    'assets/icons/tander_icon.png',
                    width: 52,
                    height: 52,
                    semanticLabel: 'Tander logo',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: 26,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow() {
    return Row(
      children: [
        const SizedBox(width: 40),
        const Spacer(),
        StepBadgeEntry(
          child: Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Step 4 of 5',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildWhiteSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const AuthSheetHandle(),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Center(
                child: RegistrationStepDots(currentStep: 4, totalSteps: 5),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: _buildFormContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add Your Photos',
          style: AppTypography.h1.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Add up to $_maxPhotos photos. Your first photo is your profile '
          'picture.',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_offlineError != null) ...[
          // Offline-retry banner — see network_exception_handler.dart policy.
          AuthErrorDisplay.banner(
            message: _offlineError!.userMessage,
            autoDismiss: false,
            onRetry: _retryUpload,
            onDismiss: () => setState(() => _offlineError = null),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildPhotoGrid(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your photos are only visible to verified members.',
          style: AppTypography.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildContinueButton(),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: GestureDetector(
            onTap: _onSkip,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                "I'll add photos later",
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
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

  Widget _buildContinueButton() {
    if (!_hasAtLeastOnePhoto) {
      return const TanderButton(
        label: 'Add a photo to continue',
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
}

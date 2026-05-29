import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Slide-up modal sheet matching the web's `SlideUpSheet` component.
///
/// Use the static [show] method to present modally. The sheet occupies
/// up to [maxHeightFraction] of the screen, scrolls its body, and
/// renders an optional drag handle + header with close button.
class TanderBottomSheet extends StatelessWidget {
  const TanderBottomSheet({
    required this.child,
    this.title,
    this.headerAction,
    this.showDragHandle = true,
    this.maxHeightFraction = 0.92,
    this.stickyFooter,
    super.key,
  });

  /// Content rendered inside the scrollable body area.
  final Widget child;

  /// Title displayed in the header bar. When `null`, no header is rendered.
  final String? title;

  /// Optional widget placed at the trailing end of the header row.
  final Widget? headerAction;

  /// Whether to display the centered drag indicator above the header.
  final bool showDragHandle;

  /// Maximum fraction of screen height the sheet may occupy (0.0 - 1.0).
  final double maxHeightFraction;

  /// Optional widget pinned at the bottom (outside the scrollable area).
  final Widget? stickyFooter;

  /// Present this sheet as a modal bottom sheet with a blurred backdrop.
  static Future<TOutput?> show<TOutput>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? headerAction,
    bool showDragHandle = true,
    double maxHeightFraction = 0.92,
    Widget? stickyFooter,
  }) {
    return showModalBottomSheet<TOutput>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (sheetContext) => _BackdropWrapper(
        child: TanderBottomSheet(
          title: title,
          headerAction: headerAction,
          showDragHandle: showDragHandle,
          maxHeightFraction: maxHeightFraction,
          stickyFooter: stickyFooter,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = screenHeight * maxHeightFraction;
    // Include the keyboard inset so focusable content (e.g. the Security
    // sheet's password form) lifts above the on-screen keyboard. Zero when
    // no keyboard is shown, so toggle/slider sheets are unaffected.
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom +
        MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle) const _DragHandle(),
          if (title != null) _Header(title: title!, headerAction: headerAction),
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: stickyFooter == null
                  ? EdgeInsets.only(bottom: bottomPadding)
                  : EdgeInsets.zero,
              child: child,
            ),
          ),
          if (stickyFooter != null)
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: stickyFooter,
            ),
        ],
      ),
    );
  }
}

/// Blurred backdrop that wraps the sheet content.
class _BackdropWrapper extends StatelessWidget {
  const _BackdropWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Centered 36x4 drag indicator pill.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  static const double _width = 36;
  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }
}

/// Header row with close button, title, and optional trailing action.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.headerAction});

  final String title;
  final Widget? headerAction;

  static const double _closeButtonSize = 36;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _closeButtonSize,
            height: _closeButtonSize,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Center(
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTypography.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?headerAction,
        ],
      ),
    );
  }
}

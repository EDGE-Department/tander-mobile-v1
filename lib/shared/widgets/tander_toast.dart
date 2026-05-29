import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast_card.dart';

// ── Public types ──────────────────────────────────────────────────

/// Visual variant controlling icon, color, and default duration.
enum TanderToastVariant { success, error, warning, info }

/// Immutable description of a single toast notification.
class TanderToastData {
  const TanderToastData({
    required this.message,
    this.title,
    this.variant = TanderToastVariant.info,
    this.duration,
  });

  /// Primary text displayed in the toast body.
  final String message;

  /// Optional bold heading above [message].
  final String? title;

  /// Controls icon, colors, and default auto-dismiss duration.
  final TanderToastVariant variant;

  /// Override the default auto-dismiss duration for this toast.
  final Duration? duration;
}

// ── Variant configuration ─────────────────────────────────────────

/// Resolved visual tokens for a [TanderToastVariant].
///
/// Library-internal — consumed by [TanderToastCard].
class ToastVariantConfig {
  const ToastVariantConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.progressColor,
    required this.defaultDuration,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color progressColor;
  final Duration defaultDuration;
}

/// Mapping from variant to visual config.
///
/// Library-internal — consumed by overlay + card.
const toastVariantConfigs = <TanderToastVariant, ToastVariantConfig>{
  TanderToastVariant.success: ToastVariantConfig(
    icon: Icons.check_circle_rounded,
    iconColor: AppColors.success,
    backgroundColor: AppColors.successLight,
    borderColor: Color(0x4D22C55E), // success at 30%
    progressColor: AppColors.success,
    defaultDuration: Duration(seconds: 4),
  ),
  TanderToastVariant.error: ToastVariantConfig(
    icon: Icons.cancel_rounded,
    iconColor: AppColors.danger,
    backgroundColor: AppColors.dangerLight,
    borderColor: Color(0x4DEF4444), // danger at 30%
    progressColor: AppColors.danger,
    defaultDuration: Duration(milliseconds: 5500),
  ),
  TanderToastVariant.warning: ToastVariantConfig(
    icon: Icons.warning_rounded,
    iconColor: AppColors.warning,
    backgroundColor: AppColors.warningLight,
    borderColor: Color(0x4DF59E0B), // warning at 30%
    progressColor: AppColors.warning,
    defaultDuration: Duration(milliseconds: 4500),
  ),
  TanderToastVariant.info: ToastVariantConfig(
    icon: Icons.info_rounded,
    iconColor: AppColors.info,
    backgroundColor: AppColors.infoLight,
    borderColor: Color(0x4D3B82F6), // info at 30%
    progressColor: AppColors.info,
    defaultDuration: Duration(seconds: 4),
  ),
};

// ── Internal entry model ──────────────────────────────────────────

/// Mutable tracking record for a single toast in the stack.
///
/// Library-internal — shared between overlay and card.
class ToastEntry {
  ToastEntry({
    required this.key,
    required this.toastData,
    required this.duration,
    required this.onDismiss,
  });

  final Key key;
  final TanderToastData toastData;
  final Duration duration;
  final void Function(ToastEntry entry) onDismiss;
}

// ── Overlay manager ───────────────────────────────────────────────

/// Stateful overlay that manages a stack of toast notifications.
///
/// Wrap your app (or a subtree) with this widget, then call
/// [TanderToastOverlay.show] from anywhere beneath it to push a toast.
///
/// Maximum 3 toasts visible simultaneously — the oldest is evicted
/// when a fourth arrives.
class TanderToastOverlay extends StatefulWidget {
  const TanderToastOverlay({required this.child, super.key});

  /// The app content rendered beneath the toast overlay.
  final Widget child;

  /// Push a toast onto the overlay stack nearest to [context].
  static void show(BuildContext context, TanderToastData toast) {
    final state = context.findAncestorStateOfType<TanderToastOverlayState>();
    if (state == null) {
      throw FlutterError(
        'TanderToastOverlay.show() called without a '
        'TanderToastOverlay ancestor in the widget tree.',
      );
    }
    state._addToast(toast);
  }

  @override
  State<TanderToastOverlay> createState() => TanderToastOverlayState();
}

/// Visible so [TanderToastOverlay.show] can locate it via
/// [findAncestorStateOfType]. Do not interact with this directly.
class TanderToastOverlayState extends State<TanderToastOverlay> {
  final List<ToastEntry> _entries = [];
  OverlayEntry? _overlayEntry;

  static const int _maxVisible = 3;

  void _addToast(TanderToastData toastData) {
    final config = toastVariantConfigs[toastData.variant]!;
    final duration = toastData.duration ?? config.defaultDuration;

    final entry = ToastEntry(
      key: UniqueKey(),
      toastData: toastData,
      duration: duration,
      onDismiss: _removeEntry,
    );

    setState(() {
      _entries.add(entry);
      // Cap visible at _maxVisible — drop oldest.
      while (_entries.length > _maxVisible) {
        _entries.removeAt(0);
      }
    });

    _syncOverlay();
  }

  void _removeEntry(ToastEntry entry) {
    if (!mounted) return;
    setState(() {
      _entries.remove(entry);
    });
    _syncOverlay();
  }

  void _syncOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (_entries.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (_) => _ToastStack(entries: List.unmodifiable(_entries)),
    );

    // Insert after the current frame to avoid build-phase mutations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = Overlay.of(context);
      if (_overlayEntry != null) {
        overlay.insert(_overlayEntry!);
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Toast stack (positioned overlay content) ──────────────────────

class _ToastStack extends StatelessWidget {
  const _ToastStack({required this.entries});

  final List<ToastEntry> entries;

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.viewPaddingOf(context).bottom + AppSpacing.lg;

    // Tablet: bottom-right. Phone: bottom-center.
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Positioned(
      bottom: bottomPadding,
      right: isTablet ? AppSpacing.lg : null,
      left: isTablet ? null : AppSpacing.md,
      child: SizedBox(
        width: isTablet
            ? 360
            : MediaQuery.sizeOf(context).width - 2 * AppSpacing.md,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isTablet
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
          children: [
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: TanderToastCard(key: entry.key, entry: entry),
              ),
          ],
        ),
      ),
    );
  }
}

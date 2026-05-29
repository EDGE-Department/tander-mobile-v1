import 'package:flutter/material.dart';

/// Three-way result of the v2 call-conflict modal.
enum CallConflictChoice {
  /// User chose the primary action (e.g. "Take it here", "End and call").
  primary,

  /// User chose the secondary action (currently unused — kept for parity
  /// with web's API surface).
  secondary,

  /// User dismissed or chose Cancel / Stay there / OK.
  cancel,
}

/// Options for [showV2CallConflictDialog]. Mirrors the web's
/// `ConflictDialogOptions` interface so the call-site code reads the
/// same on both platforms.
class V2CallConflictDialogOptions {
  const V2CallConflictDialogOptions({
    required this.title,
    required this.description,
    this.primary,
    this.secondary,
    this.cancel = 'Cancel',
    this.primaryDanger = false,
  });

  final String title;
  final String description;

  /// Primary button label. Null = no primary button (info-only dialog).
  final String? primary;

  /// Secondary destructive label. Null = hidden (most cases).
  final String? secondary;

  /// Cancel button label. Defaults to "Cancel"; pass "OK" for info-only.
  final String cancel;

  /// If true, primary button is rendered in danger color (red).
  final bool primaryDanger;
}

/// Imperative entry point — show a v2 call conflict modal and await the
/// user's choice. Non-dismissible by tapping outside (forces an explicit
/// choice).
Future<CallConflictChoice> showV2CallConflictDialog(
  BuildContext context,
  V2CallConflictDialogOptions opts,
) async {
  final result = await showDialog<CallConflictChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _V2CallConflictDialog(opts: opts),
  );
  return result ?? CallConflictChoice.cancel;
}

class _V2CallConflictDialog extends StatelessWidget {
  const _V2CallConflictDialog({required this.opts});
  final V2CallConflictDialogOptions opts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Phone-incoming-style icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5), // light orange backdrop
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_callback,
                color: Color(0xFFFF6B35),
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              opts.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              opts.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(CallConflictChoice.cancel),
                    child: Text(opts.cancel),
                  ),
                ),
                if (opts.secondary != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(CallConflictChoice.secondary),
                      child: Text(opts.secondary!),
                    ),
                  ),
                ],
                if (opts.primary != null) ...<Widget>[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: opts.primaryDanger
                            ? Colors.redAccent
                            : const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          Navigator.of(context).pop(CallConflictChoice.primary),
                      child: Text(opts.primary!),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

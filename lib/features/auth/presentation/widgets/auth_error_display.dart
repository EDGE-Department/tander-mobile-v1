import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Visual tier for an authentication-flow error.
///
/// Tier policy (see [AuthErrorDisplay]):
///
///   * [fieldInline] — inline under a [TextFormField] that failed validation
///     AND has been touched. Single-line red copy with a small leading icon.
///   * [formBanner]  — full-width card rendered above the form. Use for API
///     errors (5xx, network), duplicate detection, age/fraud, and any
///     terminal-but-recoverable failure that calls for a Retry affordance.
///   * [toast]       — delegated to [TanderToastOverlay]; transient,
///     non-blocking notifications (success confirmations, soft warnings).
///     This widget does NOT render toast — call the overlay directly.
enum AuthErrorTier { fieldInline, formBanner, toast }

/// Unified visual implementation for the inline and banner error tiers in
/// the registration / auth flow. Toast tier is delegated to
/// `TanderToastOverlay` — there is no `.toast()` factory here.
///
/// **When to use which tier:**
///
///   * Inline:   reactive field-level validators (required, length, format).
///   * Banner:   form-submission failures, server-side validation, network
///               errors, and any user-actionable error where the user should
///               read and optionally retry without leaving the screen.
///   * Toast:    background-task feedback, success states, soft warnings.
class AuthErrorDisplay extends StatefulWidget {
  /// Inline field error — red text + icon, sits below the field.
  ///
  /// Use when a `TextFormField` validator returned an error AND the field
  /// has been touched. Single line; long messages truncate with ellipsis.
  const AuthErrorDisplay.inline({required String message, Key? key})
      : this._(
          tier: AuthErrorTier.fieldInline,
          message: message,
          key: key,
        );

  /// Form banner — full-width card, icon + optional title + message.
  ///
  /// Use for API errors, 5xx, duplicate detection, age/fraud, and network
  /// failures. Auto-dismissible after 12 seconds (when [autoDismiss] is true,
  /// the default), OR until the user dismisses (X button). Pass [onRetry] to
  /// surface a "Try again" link below the message; pass [onDismiss] to be
  /// notified when the banner closes.
  ///
  /// Set [autoDismiss] to `false` for offline / connectivity errors that need
  /// to stay visible until the user takes action (retry or close).
  const AuthErrorDisplay.banner({
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String? title,
    bool autoDismiss = true,
    Key? key,
  }) : this._(
          tier: AuthErrorTier.formBanner,
          message: message,
          title: title,
          onRetry: onRetry,
          onDismiss: onDismiss,
          autoDismiss: autoDismiss,
          key: key,
        );

  const AuthErrorDisplay._({
    required this.tier,
    required this.message,
    this.title,
    this.onRetry,
    this.onDismiss,
    this.autoDismiss = true,
    super.key,
  });

  final AuthErrorTier tier;
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool autoDismiss;

  static const Duration _bannerAutoDismiss = Duration(seconds: 12);

  @override
  State<AuthErrorDisplay> createState() => _AuthErrorDisplayState();
}

class _AuthErrorDisplayState extends State<AuthErrorDisplay> {
  Timer? _autoDismissTimer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    if (widget.tier == AuthErrorTier.formBanner && widget.autoDismiss) {
      _autoDismissTimer = Timer(
        AuthErrorDisplay._bannerAutoDismiss,
        _handleDismiss,
      );
    }
  }

  @override
  void didUpdateWidget(covariant AuthErrorDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tier == AuthErrorTier.formBanner &&
        widget.message != oldWidget.message) {
      // Message changed — restart the auto-dismiss countdown so a new error
      // gets its full 12-second read window. Skipped when [autoDismiss] is
      // false (sticky banner — used for offline/connectivity errors).
      _autoDismissTimer?.cancel();
      _isDismissed = false;
      if (widget.autoDismiss) {
        _autoDismissTimer = Timer(
          AuthErrorDisplay._bannerAutoDismiss,
          _handleDismiss,
        );
      }
    }
  }

  void _handleDismiss() {
    if (!mounted || _isDismissed) return;
    setState(() => _isDismissed = true);
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();
    return switch (widget.tier) {
      AuthErrorTier.fieldInline => _buildInline(),
      AuthErrorTier.formBanner => _buildBanner(),
      AuthErrorTier.toast => const SizedBox.shrink(),
    };
  }

  // ── Inline ──────────────────────────────────────────────────────────

  Widget _buildInline() {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 14,
            color: AppColors.danger,
            semanticLabel: 'Error',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                color: AppColors.danger,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner ──────────────────────────────────────────────────────────

  Widget _buildBanner() {
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Error',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33C0392B)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 24,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null) ...[
                    Text(
                      widget.title!,
                      style: AppTypography.label.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    widget.message,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: widget.onRetry,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Try again',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.onDismiss != null) ...[
              const SizedBox(width: 8),
              Semantics(
                label: 'Dismiss error',
                button: true,
                child: SizedBox(
                  // 44x44 hit area for an 18px glyph — keeps the visual small
                  // while meeting the >=44px touch-target minimum (60+ audience).
                  width: 44,
                  height: 44,
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    splashRadius: 22,
                    onPressed: _handleDismiss,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

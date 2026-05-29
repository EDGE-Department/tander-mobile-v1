import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Full-screen non-cancellable confirmation card that auto-dismisses.
///
/// Shows a scaling green checkmark + short message for [displayDuration],
/// then pops itself off the navigator. Use it just before navigating to
/// the next step in a multi-step flow to give the user concrete feedback
/// that the previous step succeeded.
///
/// Usage:
///   await AuthSuccessConfirmation.show(context, 'Profile saved!');
///   if (mounted) context.go(...);
class AuthSuccessConfirmation extends StatefulWidget {
  const AuthSuccessConfirmation._({required this.message});

  final String message;

  static bool _isShowing = false;
  static const Duration displayDuration = Duration(milliseconds: 700);

  /// Shows the confirmation card for [displayDuration] then auto-dismisses.
  /// Returns when dismissed. Idempotent: if already showing, returns
  /// immediately without stacking a second instance.
  static Future<void> show(BuildContext context, String message) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AuthSuccessConfirmation._(message: message),
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<AuthSuccessConfirmation> createState() =>
      _AuthSuccessConfirmationState();
}

class _AuthSuccessConfirmationState extends State<AuthSuccessConfirmation> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(AuthSuccessConfirmation.displayDuration, () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CheckIcon(reduceMotion: reduceMotion),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon({required this.reduceMotion});
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    const child = Icon(
      Icons.check_circle_rounded,
      size: 64,
      color: Color(0xFF20BF68), // brand green (matches authGradient terminus)
    );
    if (reduceMotion) return child;
    return child
        .animate()
        .scale(
          begin: const Offset(0.4, 0.4),
          end: const Offset(1.0, 1.0),
          duration: 350.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 250.ms);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Resend cooldown in seconds before the user can request a new code.
const int resendCooldownSeconds = 60;

/// A "Didn't receive a code?" row with a countdown timer and resend action.
///
/// Manages its own countdown timer internally. Call [ResendTimerState.restart]
/// to reset the countdown after a successful resend.
class ResendTimer extends StatefulWidget {
  const ResendTimer({
    required this.onResend,
    this.isResending = false,
    super.key,
  });

  /// Called when the user taps "Resend code" after the cooldown expires.
  final VoidCallback onResend;

  /// Whether a resend request is currently in flight.
  final bool isResending;

  @override
  State<ResendTimer> createState() => ResendTimerState();
}

class ResendTimerState extends State<ResendTimer> {
  int _secondsLeft = resendCooldownSeconds;
  Timer? _timer;

  bool get _canResend => _secondsLeft == 0 && !widget.isResending;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Resets the countdown back to [resendCooldownSeconds].
  void restart() {
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = resendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, resendCooldownSeconds);
      });
      if (_secondsLeft == 0) _timer?.cancel();
    });
  }

  String get _formattedTime {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive a code? ",
          style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
        ),
        if (_canResend)
          GestureDetector(
            onTap: widget.onResend,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                'Resend code',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.primaryAccessible,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Text(
            'Resend in $_formattedTime',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

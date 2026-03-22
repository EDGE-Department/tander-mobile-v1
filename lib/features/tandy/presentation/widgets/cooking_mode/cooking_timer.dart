import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Elder-friendly countdown timer with circular progress ring,
/// large digital display, play/pause, reset, and quick-add chips.
class CookingTimerWidget extends StatefulWidget {
  const CookingTimerWidget({required this.initialSeconds, super.key});

  final int initialSeconds;

  @override
  State<CookingTimerWidget> createState() => _CookingTimerWidgetState();
}

class _CookingTimerWidgetState extends State<CookingTimerWidget> {
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;
  int? _startTimestamp;
  int _targetSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_remainingSeconds <= 0) return;
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      _startTimestamp = DateTime.now().millisecondsSinceEpoch;
      _targetSeconds = _remainingSeconds;
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        final elapsedSeconds = (DateTime.now().millisecondsSinceEpoch - _startTimestamp!) ~/ 1000;
        final nextValue = (_targetSeconds - elapsedSeconds).clamp(0, _targetSeconds);
        setState(() {
          _remainingSeconds = nextValue;
          if (_remainingSeconds <= 0) {
            _timer?.cancel();
            _isRunning = false;
          }
        });
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = widget.initialSeconds;
    });
  }

  void _addMinutes(int minutes) {
    setState(() => _remainingSeconds += minutes * 60);
  }

  String _formatTimer(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isZero = _remainingSeconds <= 0;
    final progressFraction = widget.initialSeconds > 0
        ? _remainingSeconds / widget.initialSeconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isRunning ? kTandyOrange : AppColors.borderLight,
          width: _isRunning ? 2 : 1.5,
        ),
        color: _isRunning ? const Color(0xFFFFFAF5) : Colors.white,
      ),
      child: Column(
        children: <Widget>[
          // Timer display
          Text(
            _formatTimer(_remainingSeconds),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: isZero
                  ? const Color(0xFFC4BBB0)
                  : (_isRunning ? const Color(0xFF9A3412) : AppColors.textStrong),
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Play/Pause with progress ring
              SizedBox(
                width: 72, height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Progress ring
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _RingPainter(
                        progress: progressFraction,
                        trackColor: const Color(0xFFF0EDE7),
                        progressColor: isZero ? const Color(0xFFE0D9CE) : kTandyOrange,
                        strokeWidth: 4,
                      ),
                    ),
                    // Button
                    SizedBox(
                      width: 58, height: 58,
                      child: FilledButton(
                        onPressed: isZero ? null : _togglePlayPause,
                        style: FilledButton.styleFrom(
                          backgroundColor: isZero ? const Color(0xFFE8E3DA) : kTandyOrange,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: isZero ? const Color(0xFFC4BBB0) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Reset
              IconButton(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                style: IconButton.styleFrom(
                  fixedSize: const Size(48, 48),
                  shape: const CircleBorder(side: BorderSide(color: AppColors.borderLight)),
                  backgroundColor: const Color(0xFFFEFCF9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick-add chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <int>[1, 5, 10].map((minutes) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ActionChip(
                label: Text('+$minutes min', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF9A3412))),
                onPressed: () => _addMinutes(minutes),
                backgroundColor: const Color(0xFFFEF0E0),
                side: BorderSide(color: kTandyOrange.withAlpha(38)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular progress ring.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      progressColor != oldDelegate.progressColor;
}

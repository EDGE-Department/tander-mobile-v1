import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

const List<String> _phaseSequence = <String>['inhale', 'hold', 'exhale', 'rest'];

const Map<String, int> _phaseDurations = <String, int>{
  'inhale': kBreathingInhaleDuration,
  'hold': kBreathingHoldDuration,
  'exhale': kBreathingExhaleDuration,
  'rest': kBreathingRestDuration,
};

const Map<String, Color> _phaseColors = <String, Color>{
  'idle': kTandyTeal,
  'inhale': kInhaleColor,
  'hold': kHoldColor,
  'exhale': kExhaleColor,
  'rest': kRestColor,
};

const Map<String, String> _phaseLabels = <String, String>{'idle': 'Ready', 'inhale': 'Breathe In', 'hold': 'Hold', 'exhale': 'Breathe Out', 'rest': 'Rest'};

const Map<String, String> _phaseInstructions = <String, String>{'idle': 'Press play when you are ready', 'inhale': 'Breathe in through your nose', 'hold': 'Hold your breath gently', 'exhale': 'Breathe out through your mouth', 'rest': 'Relax and settle'};

class TandyBreathingPanel extends StatefulWidget {
  const TandyBreathingPanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  State<TandyBreathingPanel> createState() => _TandyBreathingPanelState();
}

class _TandyBreathingPanelState extends State<TandyBreathingPanel>
    with SingleTickerProviderStateMixin {
  bool _isRunning = false;
  String _phase = 'idle';
  int _secondsLeft = 0;
  int _cycleCount = 0;
  int _phaseIndex = 0;
  bool _isComplete = false;
  Timer? _timer;
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _orbController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _isComplete = false;
      _cycleCount = 0;
      _phaseIndex = 0;
      _phase = _phaseSequence[0];
      _secondsLeft = _phaseDurations[_phase]!;
    });
    _startTimer();
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _phase = 'idle';
      _secondsLeft = 0;
      _cycleCount = 0;
      _phaseIndex = 0;
      _isComplete = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        _advancePhase();
      }
    });
  }

  void _advancePhase() {
    _phaseIndex = (_phaseIndex + 1) % _phaseSequence.length;
    if (_phaseIndex == 0) {
      _cycleCount++;
      if (_cycleCount >= kBreathingTotalCycles) {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _phase = 'idle';
          _secondsLeft = 0;
          _isComplete = true;
        });
        return;
      }
    }
    setState(() {
      _phase = _phaseSequence[_phaseIndex];
      _secondsLeft = _phaseDurations[_phase]!;
    });
  }

  String _formatClock(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int get _totalElapsed {
    final completedCycleSeconds = _cycleCount * kBreathingCycleDuration;
    final currentPhaseElapsed = (_phaseDurations[_phase] ?? 0) - _secondsLeft;
    final phasesBeforeCurrent = _phaseSequence.sublist(0, _phaseIndex);
    final phaseOffsetSeconds = phasesBeforeCurrent.fold<int>(0, (sum, phase) => sum + (_phaseDurations[phase] ?? 0));
    return completedCycleSeconds + phaseOffsetSeconds + currentPhaseElapsed;
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _phaseColors[_phase] ?? kTandyTeal;
    final phaseLabel = _phaseLabels[_phase] ?? '';
    final phaseInstruction = _phaseInstructions[_phase] ?? '';
    final remainingTotal = kBreathingSessionDuration - _totalElapsed;

    return Container(
      color: AppColors.canvas,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFFFEF0E0)),
                    child: const Icon(Icons.air, size: 18, color: kTandyOrange),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Breathing Exercise', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textStrong)),
                        Text('4-7-8 technique \u00B7 84 seconds', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, size: 16),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: const BorderSide(color: AppColors.borderLight)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.borderLight),

            // Body
            Expanded(
              child: _isComplete ? _CompletionView(onReset: _reset) : _BreathingBody(
                phase: _phase,
                phaseColor: phaseColor,
                phaseLabel: phaseLabel,
                phaseInstruction: phaseInstruction,
                secondsLeft: _secondsLeft,
                remainingTotal: remainingTotal,
                cycleCount: _cycleCount,
                isRunning: _isRunning,
                orbController: _orbController,
                onStart: _start,
                onPause: _pause,
                onReset: _reset,
                formatClock: _formatClock,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingBody extends StatelessWidget {
  const _BreathingBody({
    required this.phase, required this.phaseColor, required this.phaseLabel,
    required this.phaseInstruction, required this.secondsLeft, required this.remainingTotal,
    required this.cycleCount, required this.isRunning, required this.orbController,
    required this.onStart, required this.onPause, required this.onReset,
    required this.formatClock,
  });

  final String phase;
  final Color phaseColor;
  final String phaseLabel;
  final String phaseInstruction;
  final int secondsLeft;
  final int remainingTotal;
  final int cycleCount;
  final bool isRunning;
  final AnimationController orbController;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final String Function(int) formatClock;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Orb
            AnimatedBuilder(
              animation: orbController,
              builder: (_, __) {
                final scale = phase == 'idle'
                    ? 1.0 + 0.012 * math.sin(orbController.value * math.pi)
                    : _orbScaleForPhase(phase, orbController.value);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[phaseColor.withAlpha(204), phaseColor.withAlpha(77)],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: phaseColor.withAlpha(77), blurRadius: 40, spreadRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        secondsLeft > 0 ? secondsLeft.toString() : '',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Phase label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                phaseLabel,
                key: ValueKey(phase),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: phaseColor, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(phaseInstruction, style: const TextStyle(fontSize: 15, color: AppColors.textBody)),
            const SizedBox(height: 24),

            // Session info
            Text('Cycle ${cycleCount + 1} of $kBreathingTotalCycles', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(formatClock(remainingTotal.clamp(0, kBreathingSessionDuration)), style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isRunning)
                  _ControlButton(icon: Icons.pause, onTap: onPause, color: phaseColor)
                else
                  _ControlButton(icon: Icons.play_arrow, onTap: onStart, color: phaseColor),
                const SizedBox(width: 16),
                _ControlButton(icon: Icons.refresh, onTap: onReset, color: AppColors.textMuted, isOutlined: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _orbScaleForPhase(String currentPhase, double animValue) {
    return switch (currentPhase) {
      'inhale' => 1.0 + 0.24 * animValue,
      'hold' => 1.24 + 0.015 * math.sin(animValue * math.pi),
      'exhale' => 1.24 - 0.26 * animValue,
      'rest' => 0.98 + 0.02 * animValue,
      _ => 1.0,
    };
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onTap, required this.color, this.isOutlined = false});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          fixedSize: const Size(56, 56),
          shape: const CircleBorder(),
          side: const BorderSide(color: AppColors.borderLight),
          foregroundColor: color,
        ),
        child: Icon(icon, size: 22),
      );
    }
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        fixedSize: const Size(64, 64),
        shape: const CircleBorder(),
        backgroundColor: color,
      ),
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kTandyGreen.withAlpha(20),
                border: Border.all(color: kTandyGreen.withAlpha(77), width: 2),
              ),
              child: const Icon(Icons.check, size: 48, color: kTandyGreen),
            ),
            const SizedBox(height: 24),
            const Text('Session Complete', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
            const SizedBox(height: 8),
            const Text('4 cycles \u00B7 84 seconds of calm', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            const Text('Notice how you feel. Carry this stillness forward.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6)),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kTandyTeal, width: 2),
                foregroundColor: kTandyTeal,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('Do Another Session', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

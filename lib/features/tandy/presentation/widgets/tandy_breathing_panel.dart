import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constellation_bg.dart';

const List<String> _phaseSequence = ['inhale', 'hold', 'exhale', 'rest'];
const Map<String, int> _phaseDurations = {
  'inhale': kBreathingInhaleDuration,
  'hold': kBreathingHoldDuration,
  'exhale': kBreathingExhaleDuration,
  'rest': kBreathingRestDuration,
};
const Map<String, Color> _phaseColors = {
  'idle': kTandyTeal,
  'inhale': kInhaleColor,
  'hold': kHoldColor,
  'exhale': kExhaleColor,
  'rest': kRestColor,
};
const Map<String, String> _phaseLabels = {
  'idle': 'Ready',
  'inhale': 'Breathe In',
  'hold': 'Hold',
  'exhale': 'Breathe Out',
  'rest': 'Rest',
};
const Map<String, String> _phaseInstructions = {
  'idle': 'Press play when you are ready',
  'inhale': 'Through the nose, slow and steady.',
  'hold': 'Stay soft. No strain in the jaw or throat.',
  'exhale': 'Out through the mouth, longer than the inhale.',
  'rest': 'A brief pause before the next inhale arrives.',
};

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

  int get _totalElapsed {
    final completedCycleSeconds = _cycleCount * kBreathingCycleDuration;
    final currentPhaseElapsed = (_phaseDurations[_phase] ?? 0) - _secondsLeft;
    final phasesBeforeCurrent = _phaseSequence.sublist(0, _phaseIndex);
    final phaseOffsetSeconds = phasesBeforeCurrent.fold<int>(
      0,
      (sum, phase) => sum + (_phaseDurations[phase] ?? 0),
    );
    return completedCycleSeconds + phaseOffsetSeconds + currentPhaseElapsed;
  }

  String _formatClock(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final phaseColor = _phaseColors[_phase] ?? kTandyTeal;
    final remainingTotal = kBreathingSessionDuration - _totalElapsed;
    final progress = _totalElapsed / kBreathingSessionDuration;
    final isTablet = MediaQuery.sizeOf(context).width >= 1024;

    return Container(
      color: AppColors.canvas,
      child: Stack(
        children: [
          const Positioned.fill(child: TandyConstellationBg()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, color: AppColors.borderLight),
                Expanded(
                  child: _isComplete
                      ? _CompletionView(onReset: _reset)
                      : isTablet
                      ? _buildTabletLayout(phaseColor, remainingTotal, progress)
                      : _buildPhoneLayout(phaseColor, remainingTotal, progress),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: const Color(0xFFFEF0E0),
            ),
            child: const Icon(Icons.spa, size: 18, color: kTandyOrange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4-7-8 Breathing',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Constellation-guided calm',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Status badge
          MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.noScaling),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kTandyTeal.withAlpha(15),
                border: Border.all(color: kTandyTeal.withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kTandyTeal,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRunning ? 'In session' : 'Ready',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B7D73),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tablet: two-column layout ──────────────────────────────────────────

  Widget _buildTabletLayout(
    Color phaseColor,
    int remainingTotal,
    double progress,
  ) {
    return Row(
      children: [
        // Left: Info panel
        SizedBox(
          width: 380,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: _buildInfoPanel(phaseColor, remainingTotal, progress),
          ),
        ),
        // Right: Orb + controls + breathing path
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                _buildOrbSection(phaseColor, orbSize: 200),
                const SizedBox(height: 28),
                _buildControls(phaseColor),
                const SizedBox(height: 32),
                _buildBreathingPathCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Phone: single-column ───────────────────────────────────────────────

  Widget _buildPhoneLayout(
    Color phaseColor,
    int remainingTotal,
    double progress,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tag pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _tagPill('4-7-8 Technique'),
                const SizedBox(width: 8),
                _tagPill('4 guided cycles'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOrbSection(phaseColor, orbSize: 160),
          const SizedBox(height: 20),
          // Session stats row
          Row(
            children: [
              Expanded(
                child: _statBox(
                  'TIME LEFT',
                  _formatClock(
                    remainingTotal.clamp(0, kBreathingSessionDuration),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox('CYCLE', '$_cycleCount/$kBreathingTotalCycles'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          _buildProgressBar(progress),
          const SizedBox(height: 24),
          _buildControls(phaseColor),
          const SizedBox(height: 24),
          _buildBreathingPathCard(),
        ],
      ),
    );
  }

  // ── Shared components ──────────────────────────────────────────────────

  Widget _buildInfoPanel(
    Color phaseColor,
    int remainingTotal,
    double progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag pills
        Row(
          children: [
            _tagPill('4-7-8 Technique'),
            const SizedBox(width: 8),
            _tagPill('4 guided cycles'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Breathe with the orb.\nLet the sky stay still.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'A 4-7-8 flow built around slower exhales and a fixed constellation backdrop.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        // Session stats
        const Text(
          'SESSION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statBox(
                'TIME LEFT',
                _formatClock(
                  remainingTotal.clamp(0, kBreathingSessionDuration),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox('CYCLE', '$_cycleCount/$kBreathingTotalCycles'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildProgressBar(progress),
      ],
    );
  }

  Widget _buildOrbSection(Color phaseColor, {required double orbSize}) {
    final phaseLabel = _phaseLabels[_phase] ?? '';
    final phaseInstruction = _phaseInstructions[_phase] ?? '';

    return Column(
      children: [
        // Title above orb
        Text(
          _phase == 'idle' ? 'Let the orb guide the breath' : phaseLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: phaseColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          phaseInstruction,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Orb
        AnimatedBuilder(
          animation: _orbController,
          builder: (_, _) {
            final scale = _phase == 'idle'
                ? 1.0 + 0.012 * math.sin(_orbController.value * math.pi)
                : _orbScaleForPhase(_phase, _orbController.value);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      phaseColor.withAlpha(204),
                      phaseColor.withAlpha(77),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: phaseColor.withAlpha(77),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _secondsLeft > 0 ? _secondsLeft.toString() : phaseLabel,
                        style: TextStyle(
                          fontSize: _secondsLeft > 0 ? 52 : 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (_secondsLeft > 0)
                        Text(
                          phaseLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(Color phaseColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        _ControlButton(
          icon: Icons.refresh,
          onTap: _reset,
          color: AppColors.textMuted,
          isOutlined: true,
          size: 50,
        ),
        const SizedBox(width: 16),
        // Play/Pause (large center)
        _ControlButton(
          icon: _isRunning ? Icons.pause : Icons.play_arrow,
          onTap: _isRunning ? _pause : _start,
          color: phaseColor,
          size: 72,
        ),
        const SizedBox(width: 16),
        // Cycle counter
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              '$_cycleCount\n/$kBreathingTotalCycles',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textBody,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingPathCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BREATHING PATH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          _pathStep(
            1,
            'Inhale',
            _phaseInstructions['inhale']!,
            '${kBreathingInhaleDuration}s',
            kInhaleColor,
            _phase == 'inhale',
          ),
          _pathStep(
            2,
            'Hold',
            _phaseInstructions['hold']!,
            '${kBreathingHoldDuration}s',
            kHoldColor,
            _phase == 'hold',
          ),
          _pathStep(
            3,
            'Exhale',
            _phaseInstructions['exhale']!,
            '${kBreathingExhaleDuration}s',
            kExhaleColor,
            _phase == 'exhale',
          ),
          _pathStep(
            4,
            'Rest',
            _phaseInstructions['rest']!,
            '${kBreathingRestDuration}s',
            kRestColor,
            _phase == 'rest',
          ),
        ],
      ),
    );
  }

  Widget _pathStep(
    int number,
    String label,
    String sub,
    String duration,
    Color color,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : color.withAlpha(30),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isActive ? color : AppColors.textStrong,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isActive ? color.withAlpha(20) : const Color(0xFFF5F0EB),
            ),
            child: Text(
              duration,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? color : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Session progress',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTandyTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: const Color(0xFFEDE8E0),
            valueColor: const AlwaysStoppedAnimation(kTandyTeal),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        color: Colors.white.withAlpha(200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        color: Colors.white.withAlpha(200),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
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
  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.isOutlined = false,
    this.size = 64,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isOutlined;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
            color: Colors.white.withAlpha(200),
          ),
          child: Icon(icon, size: size * 0.38, color: color),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: size * 0.40, color: Colors.white),
      ),
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
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kTandyGreen.withAlpha(20),
                border: Border.all(color: kTandyGreen.withAlpha(77), width: 2),
              ),
              child: const Icon(Icons.check, size: 48, color: kTandyGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Complete',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '4 cycles \u00B7 84 seconds of calm',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Notice how you feel. Carry this stillness forward.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBody,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              onPressed: onReset,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kTandyTeal, width: 2),
                foregroundColor: kTandyTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Do Another Session',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

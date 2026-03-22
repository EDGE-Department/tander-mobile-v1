import 'dart:async';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Meditation panel with 3 preset sessions, timer, and guidance steps.
class TandyMeditationPanel extends StatefulWidget {
  const TandyMeditationPanel({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  State<TandyMeditationPanel> createState() => _TandyMeditationPanelState();
}

class _TandyMeditationPanelState extends State<TandyMeditationPanel> {
  MeditationPreset? _selected;
  bool _isRunning = false;
  int _elapsed = 0;
  int _stepIndex = 0;
  bool _isComplete = false;
  Timer? _timer;

  int get _totalSeconds => (_selected?.durationMinutes ?? 0) * 60;
  int get _remainingSeconds => (_totalSeconds - _elapsed).clamp(0, _totalSeconds);
  double get _progressPercent => _totalSeconds > 0 ? _elapsed / _totalSeconds : 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectSession(MeditationPreset session) {
    _timer?.cancel();
    setState(() {
      _selected = session;
      _elapsed = 0;
      _stepIndex = 0;
      _isComplete = false;
      _isRunning = false;
    });
  }

  void _togglePlayPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final totalSteps = _selected?.guidanceSteps.length ?? 1;
    final stepDuration = totalSteps > 0 ? (_totalSeconds / totalSteps).floor().clamp(1, _totalSeconds) : 1;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = (_elapsed + 1).clamp(0, _totalSeconds);
        _stepIndex = (_elapsed ~/ stepDuration).clamp(0, totalSteps - 1);
        if (_elapsed >= _totalSeconds) {
          _timer?.cancel();
          _isRunning = false;
          _isComplete = true;
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _elapsed = 0;
      _stepIndex = 0;
      _isRunning = false;
      _isComplete = false;
    });
  }

  void _backToSelection() {
    _timer?.cancel();
    setState(() {
      _selected = null;
      _elapsed = 0;
      _stepIndex = 0;
      _isRunning = false;
      _isComplete = false;
    });
  }

  String _formatClock(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
                  if (_selected != null)
                    IconButton(
                      onPressed: _backToSelection,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: const BorderSide(color: AppColors.borderLight)),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  if (_selected != null) const SizedBox(width: 8),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFFEDE9FE)),
                    child: const Icon(Icons.self_improvement, size: 18, color: kTandyPurple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _selected?.title ?? 'Meditation',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textStrong),
                        ),
                        Text(
                          _selected != null ? '${_selected!.durationMinutes} minutes \u00B7 ${_selected!.bestFor}' : 'Choose a session to begin',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
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
              child: _selected == null
                  ? _SessionPicker(onSelect: _selectSession)
                  : _isComplete
                      ? _CompletionView(color: _selected!.color, onReset: _reset, onClose: widget.onClose)
                      : _ActiveSession(
                          session: _selected!,
                          isRunning: _isRunning,
                          remainingSeconds: _remainingSeconds,
                          progressPercent: _progressPercent,
                          stepIndex: _stepIndex,
                          formatClock: _formatClock,
                          onTogglePlayPause: _togglePlayPause,
                          onReset: _reset,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionPicker extends StatelessWidget {
  const _SessionPicker({required this.onSelect});
  final void Function(MeditationPreset) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: kMeditationPresets.map((session) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelect(session),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: session.color.withAlpha(36)),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: session.color),
                    child: const Icon(Icons.self_improvement, size: 25, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(session.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                        const SizedBox(height: 2),
                        Text(session.subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), color: session.color.withAlpha(18)),
                              child: Text('${session.durationMinutes} min', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: session.color)),
                            ),
                            const SizedBox(width: 8),
                            Text(session.bestFor, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: session.color.withAlpha(140)),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({
    required this.session, required this.isRunning, required this.remainingSeconds,
    required this.progressPercent, required this.stepIndex, required this.formatClock,
    required this.onTogglePlayPause, required this.onReset,
  });

  final MeditationPreset session;
  final bool isRunning;
  final int remainingSeconds;
  final double progressPercent;
  final int stepIndex;
  final String Function(int) formatClock;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final currentGuidance = session.guidanceSteps[stepIndex.clamp(0, session.guidanceSteps.length - 1)];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Timer
            Text(
              formatClock(remainingSeconds),
              style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: isRunning ? session.color : AppColors.textStrong, fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
            ),
            const SizedBox(height: 8),
            // Progress bar
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: session.color.withAlpha(26)),
              child: FractionallySizedBox(
                widthFactor: progressPercent,
                alignment: Alignment.centerLeft,
                child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: session.color)),
              ),
            ),
            const SizedBox(height: 24),
            // Guidance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: session.color.withAlpha(10),
                border: Border.all(color: session.color.withAlpha(26)),
              ),
              child: Column(
                children: <Widget>[
                  Text('Step ${stepIndex + 1} of ${session.guidanceSteps.length}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(currentGuidance, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textStrong, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FilledButton(
                  onPressed: onTogglePlayPause,
                  style: FilledButton.styleFrom(fixedSize: const Size(64, 64), shape: const CircleBorder(), backgroundColor: session.color),
                  child: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(fixedSize: const Size(56, 56), shape: const CircleBorder(), side: const BorderSide(color: AppColors.borderLight)),
                  child: const Icon(Icons.refresh, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.color, required this.onReset, required this.onClose});
  final Color color;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_outline, size: 80, color: color),
            const SizedBox(height: 24),
            const Text('Session Complete', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
            const SizedBox(height: 8),
            const Text('Beautiful. You gave yourself the gift of stillness.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.textBody, height: 1.6)),
            const SizedBox(height: 28),
            FilledButton(onPressed: onClose, style: FilledButton.styleFrom(backgroundColor: color, minimumSize: const Size(200, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700))),
            const SizedBox(height: 10),
            TextButton(onPressed: onReset, child: Text('Do Again', style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

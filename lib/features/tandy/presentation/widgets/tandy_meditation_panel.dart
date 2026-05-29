import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constellation_bg.dart';

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
  int get _remainingSeconds =>
      (_totalSeconds - _elapsed).clamp(0, _totalSeconds);
  double get _progressPercent =>
      _totalSeconds > 0 ? _elapsed / _totalSeconds : 0;

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
    final stepDuration = totalSteps > 0
        ? (_totalSeconds / totalSteps).floor().clamp(1, _totalSeconds)
        : 1;
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
      child: Stack(
        children: [
          const Positioned.fill(child: TandyConstellationBg()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Divider(height: 1, color: AppColors.borderLight),
                Expanded(
                  child: _selected == null
                      ? _SessionLanding(onSelect: _selectSession)
                      : _isComplete
                      ? _CompletionView(
                          color: _selected!.color,
                          onReset: _reset,
                          onClose: widget.onClose,
                        )
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          if (_selected != null) ...[
            IconButton(
              onPressed: _backToSelection,
              icon: const Icon(Icons.arrow_back, size: 16),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: const Color(0xFFEDE9FE),
            ),
            child: const Icon(
              Icons.self_improvement,
              size: 18,
              color: kTandyPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selected?.title ?? 'Meditation',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textStrong,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selected != null
                      ? '${_selected!.durationMinutes} min \u00B7 ${_selected!.bestFor}'
                      : 'Guided mindfulness',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
}

// ── Landing page with hero + session cards ────────────────────────────────

class _SessionLanding extends StatelessWidget {
  const _SessionLanding({required this.onSelect});
  final void Function(MeditationPreset) onSelect;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withAlpha(220),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: isWide ? _buildHeroWide() : _buildHeroNarrow(),
          ),
          const SizedBox(height: 24),
          // Session cards
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: kMeditationPresets
                  .map(
                    (session) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: session == kMeditationPresets.last ? 0 : 12,
                        ),
                        child: _SessionCard(
                          session: session,
                          onSelect: onSelect,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            ...kMeditationPresets.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionCard(session: session, onSelect: onSelect),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroWide() {
    return Row(
      children: [
        Expanded(child: _buildHeroText()),
        const SizedBox(width: 32),
        _buildOrb(),
      ],
    );
  }

  Widget _buildHeroNarrow() {
    return Column(
      children: [_buildOrb(), const SizedBox(height: 20), _buildHeroText()],
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _tagPill('Constellation ambience'),
            _tagPill('Gentle pacing'),
            _tagPill('Guided reflection'),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Find stillness.\nThe constellation\nstays with you.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textStrong,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose a session below — Tandy guides every moment at a pace that is yours alone.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        // Stats
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _statBadge('3', 'curated\nsessions'),
              const SizedBox(width: 10),
              _statBadge('5–10', 'minutes\neach'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrb() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [kTandyPurple.withAlpha(180), kTandyPurple.withAlpha(100)],
        ),
        boxShadow: [
          BoxShadow(
            color: kTandyPurple.withAlpha(60),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 28, color: Colors.white70),
            SizedBox(height: 6),
            Text(
              'MEDITATE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
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

  Widget _statBadge(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        color: Colors.white.withAlpha(200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kTandyPurple,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session card ──────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onSelect});
  final MeditationPreset session;
  final void Function(MeditationPreset) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(height: 3, color: session.color),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + title + duration
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: session.color,
                      ),
                      child: const Icon(
                        Icons.self_improvement,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${session.durationMinutes} min',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: session.color,
                          ),
                        ),
                        const Text(
                          'GUIDED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tags
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: session.color.withAlpha(15),
                      ),
                      child: Text(
                        session.bestFor,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: session.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF5F0EB),
                      ),
                      child: const Text(
                        '6 moments',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Step dots
                Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: session.color.withAlpha(40 + i * 15),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${session.durationMinutes} min \u00B7 6 steps',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onSelect(session),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: session.color.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Begin',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: session.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: session.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active session ────────────────────────────────────────────────────────

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({
    required this.session,
    required this.isRunning,
    required this.remainingSeconds,
    required this.progressPercent,
    required this.stepIndex,
    required this.formatClock,
    required this.onTogglePlayPause,
    required this.onReset,
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
    final isTablet = MediaQuery.sizeOf(context).width >= 1024;
    if (isTablet) return _buildTabletLayout();
    return _buildPhoneLayout();
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: session info + path
        SizedBox(
          width: 380,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildInfoPanel(),
          ),
        ),
        // Right: orb + controls
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildOrbSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tags
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tag(session.bestFor, session.color),
              const SizedBox(width: 8),
              _tag('${session.durationMinutes} min', null),
            ],
          ),
          const SizedBox(height: 16),
          // Current step highlight
          _currentStepCard(),
          const SizedBox(height: 20),
          // Orb with timer
          _buildOrb(140),
          const SizedBox(height: 20),
          _buildControls(),
          const SizedBox(height: 20),
          // Session path
          _buildSessionPath(),
          const SizedBox(height: 16),
          // Stats
          Row(
            children: [
              Expanded(
                child: _statBox('TIME LEFT', formatClock(remainingSeconds)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  'BEST FOR',
                  session.bestFor,
                  valueColor: session.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _tag(session.bestFor, session.color),
            const SizedBox(width: 8),
            _tag('${session.durationMinutes} min', null),
          ],
        ),
        const SizedBox(height: 16),
        _currentStepCard(),
        const SizedBox(height: 20),
        // Session path with progress
        _buildSessionPath(),
        const SizedBox(height: 20),
        // Stats
        Row(
          children: [
            Expanded(
              child: _statBox('TIME LEFT', formatClock(remainingSeconds)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox(
                'BEST FOR',
                session.bestFor,
                valueColor: session.color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrbSection() {
    return Column(
      children: [
        Text(
          session.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: session.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          session.subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        _buildOrb(180),
        const SizedBox(height: 28),
        _buildControls(),
      ],
    );
  }

  Widget _buildOrb(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [session.color.withAlpha(220), session.color.withAlpha(140)],
        ),
        boxShadow: [
          BoxShadow(
            color: session.color.withAlpha(60),
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
              formatClock(remainingSeconds),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              isRunning ? 'STEP ${stepIndex + 1}' : 'READY',
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
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onReset,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
              color: Colors.white.withAlpha(200),
            ),
            child: const Icon(
              Icons.refresh,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onTogglePlayPause,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: session.color,
              boxShadow: [
                BoxShadow(
                  color: session.color.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              isRunning ? Icons.pause : Icons.play_arrow,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              '${stepIndex + 1}\n/${session.guidanceSteps.length}',
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

  Widget _currentStepCard() {
    final currentGuidance = session
        .guidanceSteps[stepIndex.clamp(0, session.guidanceSteps.length - 1)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(220),
        border: Border(left: BorderSide(color: session.color, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${stepIndex + 1} OF ${session.guidanceSteps.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: session.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentGuidance,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Let the pace stay gentle. There is no rush.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionPath() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withAlpha(200),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SESSION PATH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '${(progressPercent * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: session.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: const Color(0xFFEDE8E0),
              valueColor: AlwaysStoppedAnimation(session.color),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(session.guidanceSteps.length, (i) {
            final isActive = i == stepIndex;
            final isDone = i < stepIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? session.color
                          : isDone
                          ? session.color.withAlpha(40)
                          : Colors.transparent,
                      border: Border.all(
                        color: isActive
                            ? session.color
                            : isDone
                            ? session.color.withAlpha(60)
                            : AppColors.borderLight,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? Icon(Icons.check, size: 12, color: session.color)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      session.guidanceSteps[i],
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? AppColors.textStrong
                            : AppColors.textMuted,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, {Color? valueColor}) {
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        color: color != null
            ? color.withAlpha(15)
            : Colors.white.withAlpha(200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textBody,
        ),
      ),
    );
  }
}

// ── Completion ─────────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.color,
    required this.onReset,
    required this.onClose,
  });
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
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: color),
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
              'Beautiful. You gave yourself the gift of stillness.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textBody,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReset,
              child: Text(
                'Do Again',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

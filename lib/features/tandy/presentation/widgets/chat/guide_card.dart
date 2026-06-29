import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Category color lookup with fallback.
Color _categoryColor(String? category) {
  return switch (category?.toLowerCase()) {
    'gardening' => const Color(0xFF16A34A),
    'technology' => const Color(0xFF4F46E5),
    'health' => kTandyTeal,
    'cooking' => kTandyOrange,
    'fitness' => const Color(0xFFEF4444),
    _ => kTandyTeal,
  };
}

/// Step-by-step guide wizard card with dot navigation and progress bar.
class GuideCardWidget extends StatefulWidget {
  const GuideCardWidget({
    required this.guideData,
    required this.title,
    super.key,
  });

  final GuideBlockData guideData;
  final String title;

  @override
  State<GuideCardWidget> createState() => _GuideCardWidgetState();
}

class _GuideCardWidgetState extends State<GuideCardWidget> {
  int _currentStep = 0;
  bool _isCompleted = false;

  int get _totalSteps => widget.guideData.steps.length;

  double get _progressPercent =>
      _totalSteps > 0 ? (_currentStep + 1) / _totalSteps : 0;

  void _goNext() {
    if (_currentStep >= _totalSteps - 1) {
      setState(() => _isCompleted = true);
    } else {
      setState(() => _currentStep++);
    }
  }

  void _goPrevious() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _startOver() {
    setState(() {
      _currentStep = 0;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryColor(widget.guideData.category);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3DA)),
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(color: accentColor.withAlpha(10), blurRadius: 16),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(height: 4, color: accentColor),
          if (_totalSteps == 0) ...<Widget>[
            _Header(
              title: widget.title,
              category: widget.guideData.category,
              color: accentColor,
            ),
            const _EmptyStepsView(),
          ] else if (_isCompleted)
            _CompletionView(color: accentColor, onStartOver: _startOver)
          else ...<Widget>[
            _Header(
              title: widget.title,
              category: widget.guideData.category,
              color: accentColor,
            ),
            _ProgressBar(percent: _progressPercent, color: accentColor),
            _StepContent(
              step: widget.guideData.steps[_currentStep],
              stepIndex: _currentStep,
              totalSteps: _totalSteps,
              color: accentColor,
            ),
            _Navigation(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              color: accentColor,
              onPrevious: _goPrevious,
              onNext: _goNext,
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.category,
    required this.color,
  });
  final String title;
  final String? category;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(20),
              border: Border.all(color: color.withAlpha(34)),
            ),
            child: Icon(Icons.menu_book, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2A26),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: color.withAlpha(20),
            ),
            child: Text(
              category ?? 'Guide',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent, required this.color});
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          widthFactor: percent,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[color, color.withAlpha(204)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.color,
  });
  final GuideStep step;
  final int stepIndex;
  final int totalSteps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Step ${stepIndex + 1} of $totalSteps',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9B8F80),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2A26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF57534E),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStepsView extends StatelessWidget {
  const _EmptyStepsView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Text(
        'This guide is still being prepared. Please check back soon.',
        style: TextStyle(fontSize: 15, color: Color(0xFF9B8F80), height: 1.5),
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.currentStep,
    required this.totalSteps,
    required this.color,
    required this.onPrevious,
    required this.onNext,
  });
  final int currentStep;
  final int totalSteps;
  final Color color;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isFirst = currentStep == 0;
    final isLast = currentStep >= totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: isFirst ? null : onPrevious,
            icon: const Icon(Icons.chevron_left, size: 22),
            style: IconButton.styleFrom(
              fixedSize: const Size(56, 56),
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFFE8E3DA)),
              ),
              disabledForegroundColor: const Color(0xFFD5CFC4),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (index) {
                final isActive = index == currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 28 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isActive ? color : const Color(0xFFE8E3DA),
                  ),
                );
              }),
            ),
          ),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              fixedSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: const StadiumBorder(),
            ),
            child: Row(
              children: <Widget>[
                Text(
                  isLast ? 'Finish' : 'Next',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isLast) const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.color, required this.onStartOver});
  final Color color;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 64, color: color),
          const SizedBox(height: 20),
          const Text(
            'All Done!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            "You've completed this guide. Great job!",
            style: TextStyle(fontSize: 15, color: Color(0xFF9B8F80)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onStartOver,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 2),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'Start Over',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

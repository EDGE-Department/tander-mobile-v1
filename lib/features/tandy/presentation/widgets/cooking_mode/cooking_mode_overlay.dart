import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/cooking_mode/cooking_timer.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen immersive cooking experience — step-by-step instructions,
/// watermark step numbers, timers, and a Filipino-flavored completion view.
class CookingModeOverlay extends StatefulWidget {
  const CookingModeOverlay({
    required this.recipeData,
    required this.title,
    required this.onClose,
    super.key,
  });

  final RecipeBlockData recipeData;
  final String title;
  final VoidCallback onClose;

  @override
  State<CookingModeOverlay> createState() => _CookingModeOverlayState();
}

class _CookingModeOverlayState extends State<CookingModeOverlay> {
  int _currentStepIndex = 0;
  bool _isCompleted = false;

  List<RecipeInstruction> get _instructions => widget.recipeData.instructions;
  int get _totalSteps => _instructions.length;
  double get _progressPercent =>
      _totalSteps > 0 ? (_currentStepIndex + 1) / _totalSteps : 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _goNext() {
    if (_currentStepIndex < _totalSteps - 1) {
      setState(() => _currentStepIndex++);
    } else {
      setState(() => _isCompleted = true);
    }
  }

  void _goPrevious() {
    if (_currentStepIndex > 0) setState(() => _currentStepIndex--);
  }

  void _restart() {
    setState(() {
      _currentStepIndex = 0;
      _isCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentInstruction = _currentStepIndex < _instructions.length
        ? _instructions[_currentStepIndex]
        : null;
    final timerSeconds = (currentInstruction?.timerDurationMinutes ?? 0) * 60;

    return Material(
      child: Container(
        color: const Color(0xFFFFF8F0),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Header
              _CookingHeader(
                title: widget.title,
                stepLabel: _isCompleted
                    ? null
                    : 'Step ${_currentStepIndex + 1} / $_totalSteps',
                onClose: widget.onClose,
              ),

              // Progress bar
              Container(
                height: 6,
                color: const Color(0xFFF0EDE7),
                child: FractionallySizedBox(
                  widthFactor: _isCompleted ? 1.0 : _progressPercent,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(4),
                      ),
                      gradient: LinearGradient(
                        colors: _isCompleted
                            ? <Color>[kTandyGreen, const Color(0xFF34D399)]
                            : <Color>[kTandyOrange, const Color(0xFFF5A623)],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: _isCompleted
                    ? _CompletionView(
                        onRestart: _restart,
                        onClose: widget.onClose,
                      )
                    : _StepView(
                        stepNumber: _currentStepIndex + 1,
                        instruction: currentInstruction?.text ?? '',
                        timerSeconds: timerSeconds,
                      ),
              ),

              // Navigation
              if (!_isCompleted)
                _NavigationBar(
                  isFirst: _currentStepIndex == 0,
                  isLast: _currentStepIndex >= _totalSteps - 1,
                  totalSteps: _totalSteps,
                  currentStep: _currentStepIndex,
                  onPrevious: _goPrevious,
                  onNext: _goNext,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CookingHeader extends StatelessWidget {
  const _CookingHeader({
    required this.title,
    required this.onClose,
    this.stepLabel,
  });
  final String title;
  final String? stepLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        border: Border(bottom: BorderSide(color: Color(0xFFF0EDE7))),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.borderLight),
              ),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.restaurant, size: 20, color: kTandyOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textStrong,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (stepLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFFEF0E0), Color(0xFFFDE1C1)],
                ),
              ),
              child: Text(
                stepLabel!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A3412),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.stepNumber,
    required this.instruction,
    required this.timerSeconds,
  });
  final int stepNumber;
  final String instruction;
  final int timerSeconds;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Step badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFFEF0E0), Color(0xFFFDE1C1)],
                  ),
                  border: Border.all(color: kTandyOrange.withAlpha(38)),
                ),
                child: Text(
                  'Step $stepNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Instruction card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0x99FFF8F0),
                  border: Border.all(color: kTandyOrange.withAlpha(20)),
                ),
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                    height: 1.45,
                  ),
                ),
              ),
              if (timerSeconds > 0) ...<Widget>[
                const SizedBox(height: 28),
                CookingTimerWidget(initialSeconds: timerSeconds),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.isFirst,
    required this.isLast,
    required this.totalSteps,
    required this.currentStep,
    required this.onPrevious,
    required this.onNext,
  });
  final bool isFirst;
  final bool isLast;
  final int totalSteps;
  final int currentStep;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF),
        border: Border(top: BorderSide(color: Color(0xFFF0EDE7))),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: isFirst ? null : onPrevious,
            icon: const Icon(Icons.chevron_left, size: 20),
            style: IconButton.styleFrom(
              fixedSize: const Size(56, 56),
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.borderLight),
              ),
              disabledForegroundColor: const Color(0xFFC4BBB0),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (index) {
                final isActive = index == currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive ? kTandyOrange : const Color(0xFFE0D9CE),
                  ),
                );
              }),
            ),
          ),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: isLast ? kTandyGreen : kTandyOrange,
              fixedSize: const Size(130, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  isLast ? 'Done' : 'Next Step',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.onRestart, required this.onClose});
  final VoidCallback onRestart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                ),
                border: Border.all(color: const Color(0xFF6EE7B7), width: 3),
              ),
              child: const Icon(Icons.check, size: 56, color: kTandyGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Kainan na!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Time to eat!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B8F80),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have completed all the steps. Enjoy your meal!',
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
                backgroundColor: kTandyGreen,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Exit Cooking Mode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onRestart,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              child: const Text(
                'Start Over',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

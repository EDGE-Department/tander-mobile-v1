import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Primary button gradient matching web's `var(--gradient-primary-button)`.
const LinearGradient _buttonGradient = LinearGradient(
  begin: Alignment(-0.7, -1),
  end: Alignment(0.7, 1),
  colors: [Color(0xFFE67E22), Color(0xFFD06A18)],
);

/// Button shadow matching web's submit button box-shadow.
const List<BoxShadow> _submitButtonShadow = [
  BoxShadow(
    color: Color(0x80E67E22), // rgba(230,126,34,0.50)
    blurRadius: 36,
    offset: Offset(0, 12),
  ),
  BoxShadow(
    color: Color(0x1A000000), // rgba(0,0,0,0.10)
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];

// ── Submit button ───────────────────────────────────────────────────

/// Full-width gradient submit button with shimmer sweep animation,
/// scale-down tap feedback, and loading spinner state.
///
/// Matches the web's "Sign In to Tander" button: rounded-full,
/// gradient bg, deep warm shadow, ArrowRight icon, shimmer overlay.
class LoginSubmitButton extends StatefulWidget {
  const LoginSubmitButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<LoginSubmitButton> createState() => _LoginSubmitButtonState();
}

class _LoginSubmitButtonState extends State<LoginSubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isLoading;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Opacity(
        opacity: widget.isLoading ? 0.6 : 1.0,
        child: GestureDetector(
          onTapDown: isInteractive ? (_) => _scaleController.forward() : null,
          onTapUp: isInteractive ? (_) => _scaleController.reverse() : null,
          onTapCancel: isInteractive ? _scaleController.reverse : null,
          onTap: isInteractive ? widget.onPressed : null,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchComfortable,
            ),
            decoration: BoxDecoration(
              gradient: _buttonGradient,
              borderRadius: BorderRadius.circular(999),
              boxShadow: _submitButtonShadow,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shimmer sweep overlay
                const _ShimmerSweep(),

                // Button content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In to Tander',
                              style: AppTypography.bodyLg.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              PhosphorIconsBold.arrowRight,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shimmer sweep ───────────────────────────────────────────────────

/// Translucent white gradient band that sweeps left-to-right across
/// the button surface, matching the web's `animate-shimmer-sweep`.
class _ShimmerSweep extends StatefulWidget {
  const _ShimmerSweep();

  @override
  State<_ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<_ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (_, _) {
            final translateX =
                (_shimmerController.value * 3.0 - 1.0); // -1 to 2
            return FractionallySizedBox(
              widthFactor: 1.0,
              child: Transform.translate(
                offset: Offset(
                  translateX * MediaQuery.sizeOf(context).width,
                  0,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00FFFFFF),
                        Color(0x38FFFFFF), // ~22% white
                        Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

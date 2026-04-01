import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fade_slide_transition.dart';

enum AuthStatusActionStyle { primary, secondary, text }

/// Declarative action model for [AuthStatusScreen] buttons.
class AuthStatusAction {
  final String label;
  final VoidCallback onPressed;
  final AuthStatusActionStyle style;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AuthStatusAction({
    required this.label,
    required this.onPressed,
    this.style = AuthStatusActionStyle.primary,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Reusable full-screen status shell for auth flow outcomes.
///
/// Light-themed: white/F8F9FA background, shadow cards, dark text.
class AuthStatusScreen extends StatefulWidget {
  final Widget icon;
  final String title;
  final String message;
  final Widget? detail;
  final List<AuthStatusAction> actions;
  final Duration entranceDuration;

  const AuthStatusScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.detail,
    this.entranceDuration = const Duration(milliseconds: 700),
  });

  @override
  State<AuthStatusScreen> createState() => _AuthStatusScreenState();
}

class _AuthStatusScreenState extends State<AuthStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      duration: widget.entranceDuration,
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),
                FadeSlideTransition(
                  animation: _entrance,
                  interval: const Interval(0.0, 0.35, curve: Curves.easeOut),
                  slideY: 24,
                  child: widget.icon,
                ),
                const SizedBox(height: 28),
                FadeSlideTransition(
                  animation: _entrance,
                  interval: const Interval(0.18, 0.62, curve: Curves.easeOut),
                  slideY: 32,
                  child: _card(),
                ),
                const SizedBox(height: 20),
                ..._actions(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Column(
        children: [
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF141A28),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF747E93),
              height: 1.55,
            ),
          ),
          if (widget.detail != null) ...[
            const SizedBox(height: 16),
            widget.detail!,
          ],
        ],
      ),
    );
  }

  List<Widget> _actions() {
    if (widget.actions.isEmpty) return const [];

    final out = <Widget>[];
    for (var index = 0; index < widget.actions.length; index++) {
      final action = widget.actions[index];
      final start = (0.42 + (index * 0.08)).clamp(0.0, 0.95).toDouble();
      final end = (0.86 + (index * 0.09)).clamp(0.0, 1.0).toDouble();
      out.add(
        FadeSlideTransition(
          animation: _entrance,
          interval: Interval(start, end, curve: Curves.easeOut),
          slideY: 18,
          child: _buildAction(action),
        ),
      );
      if (index < widget.actions.length - 1) {
        out.add(const SizedBox(height: 12));
      }
    }
    return out;
  }

  Widget _buildAction(AuthStatusAction action) {
    return switch (action.style) {
      AuthStatusActionStyle.primary => _primaryAction(action),
      AuthStatusActionStyle.secondary => _secondaryAction(action),
      AuthStatusActionStyle.text => _textAction(action),
    };
  }

  Widget _primaryAction(AuthStatusAction action) {
    final bg = action.backgroundColor ?? AppColors.secondary;
    final fg = action.foregroundColor ?? Colors.white;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    );
    const textStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

    final button = action.icon == null
        ? ElevatedButton(
            onPressed: action.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              elevation: 6,
              shadowColor: bg.withValues(alpha: 0.35),
              textStyle: textStyle,
              shape: shape,
            ),
            child: Text(action.label),
          )
        : ElevatedButton.icon(
            onPressed: action.onPressed,
            icon: Icon(action.icon, size: 22),
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              elevation: 6,
              shadowColor: bg.withValues(alpha: 0.35),
              textStyle: textStyle,
              shape: shape,
            ),
            label: Text(action.label),
          );

    return SizedBox(width: double.infinity, height: 56, child: button);
  }

  Widget _secondaryAction(AuthStatusAction action) {
    final color = action.backgroundColor ?? AppColors.secondary;
    final fg = action.foregroundColor ?? color;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    );
    const textStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);

    final button = action.icon == null
        ? OutlinedButton(
            onPressed: action.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              side: BorderSide(color: color, width: 1.5),
              shape: shape,
              textStyle: textStyle,
            ),
            child: Text(action.label),
          )
        : OutlinedButton.icon(
            onPressed: action.onPressed,
            icon: Icon(action.icon, size: 22),
            style: OutlinedButton.styleFrom(
              foregroundColor: fg,
              side: BorderSide(color: color, width: 1.5),
              shape: shape,
              textStyle: textStyle,
            ),
            label: Text(action.label),
          );

    return SizedBox(width: double.infinity, height: 56, child: button);
  }

  Widget _textAction(AuthStatusAction action) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: action.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: action.foregroundColor ?? const Color(0xFF747E93),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        child: Text(action.label),
      ),
    );
  }
}

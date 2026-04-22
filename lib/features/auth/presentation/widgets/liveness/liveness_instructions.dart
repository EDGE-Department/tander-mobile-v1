import 'package:flutter/material.dart';

class LivenessInstructions extends StatefulWidget {
  final String instruction;
  final bool isFaceCentered;

  const LivenessInstructions({
    super.key,
    required this.instruction,
    required this.isFaceCentered,
  });

  @override
  State<LivenessInstructions> createState() => _LivenessInstructionsState();
}

class _LivenessInstructionsState extends State<LivenessInstructions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _currentInstruction = '';

  @override
  void initState() {
    super.initState();
    _currentInstruction = widget.instruction;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(LivenessInstructions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.instruction != oldWidget.instruction) {
      _controller.reverse().then((_) {
        setState(() {
          _currentInstruction = widget.instruction;
        });
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultColor = Color(0xFFE86035);
    const successColor = Color(0xFF5BBFB3);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated instruction pill
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isFaceCentered
                          ? successColor.withOpacity(0.15)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: widget.isFaceCentered
                            ? successColor.withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: widget.isFaceCentered
                          ? [
                              BoxShadow(
                                color: successColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            widget.isFaceCentered
                                ? Icons.check_circle_outline_rounded
                                : Icons.face_retouching_natural_rounded,
                            key: ValueKey(widget.isFaceCentered),
                            color: widget.isFaceCentered
                                ? successColor
                                : Colors.white70,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Instruction text
                        Text(
                          _currentInstruction,
                          style: TextStyle(
                            color: widget.isFaceCentered
                                ? successColor
                                : Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Helper text
              AnimatedOpacity(
                opacity: widget.isFaceCentered ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  'Make sure your face is well-lit',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

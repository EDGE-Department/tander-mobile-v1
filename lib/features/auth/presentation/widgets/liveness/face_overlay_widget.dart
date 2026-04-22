import 'dart:math';
import 'package:flutter/material.dart';

class FaceOverlayWidget extends StatefulWidget {
  final bool isFaceCentered;
  final double stabilityScore;

  const FaceOverlayWidget({
    super.key,
    required this.isFaceCentered,
    required this.stabilityScore,
  });

  @override
  State<FaceOverlayWidget> createState() => _FaceOverlayWidgetState();
}

class _FaceOverlayWidgetState extends State<FaceOverlayWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the oval border
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scanning line animation
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Glow animation when face is centered
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(FaceOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFaceCentered && !oldWidget.isFaceCentered) {
      _glowController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final ovalWidth = screenWidth * 0.72;
        final ovalHeight = ovalWidth * 1.3;

        const defaultColor = Color(0xFFE86035);
        const successColor = Color(0xFF5BBFB3);
        final overlayColor = widget.isFaceCentered ? successColor : defaultColor;

        return Stack(
          children: [
            // Dark overlay with oval cutout
            CustomPaint(
              size: Size(screenWidth, screenHeight),
              painter: OvalCutoutPainter(
                ovalWidth: ovalWidth,
                ovalHeight: ovalHeight,
                overlayColor: Colors.black.withOpacity(0.6),
              ),
            ),

            // Animated glow effect when face is centered
            if (widget.isFaceCentered)
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Center(
                    child: Container(
                      width: ovalWidth + 20,
                      height: ovalHeight + 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ovalWidth / 2),
                        boxShadow: [
                          BoxShadow(
                            color: successColor.withOpacity(0.4 * _glowAnimation.value),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Transparent tinted filter inside oval
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ovalWidth / 2),
                child: Container(
                  width: ovalWidth,
                  height: ovalHeight,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: widget.isFaceCentered
                          ? [
                              successColor.withOpacity(0.05),
                              successColor.withOpacity(0.12),
                            ]
                          : [
                              defaultColor.withOpacity(0.03),
                              defaultColor.withOpacity(0.08),
                            ],
                    ),
                  ),
                ),
              ),
            ),

            // Scanning line effect
            if (!widget.isFaceCentered)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  final centerY = screenHeight / 2;
                  final topY = centerY - ovalHeight / 2;
                  final scanY = topY + (ovalHeight * _scanAnimation.value);

                  return Positioned(
                    left: (screenWidth - ovalWidth) / 2 + 10,
                    top: scanY,
                    child: Container(
                      width: ovalWidth - 20,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            defaultColor.withOpacity(0.6),
                            defaultColor,
                            defaultColor.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: defaultColor.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Animated oval border
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: ovalWidth,
                    height: ovalHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: overlayColor.withOpacity(
                          widget.isFaceCentered ? 1.0 : _pulseAnimation.value,
                        ),
                        width: widget.isFaceCentered ? 4.0 : 3.0,
                      ),
                      borderRadius: BorderRadius.circular(ovalWidth / 2),
                    ),
                  ),
                );
              },
            ),

            // Corner markers
            ...buildCornerMarkers(
              screenWidth,
              screenHeight,
              ovalWidth,
              ovalHeight,
              overlayColor,
            ),

            // Progress ring when face is centered
            if (widget.isFaceCentered && widget.stabilityScore > 0)
              Center(
                child: SizedBox(
                  width: ovalWidth + 30,
                  height: ovalHeight + 30,
                  child: CustomPaint(
                    painter: ProgressRingPainter(
                      progress: widget.stabilityScore,
                      color: successColor,
                      strokeWidth: 5.0,
                    ),
                  ),
                ),
              ),

            // Checkmark when capturing
            if (widget.stabilityScore >= 1.0)
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: successColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: successColor.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  List<Widget> buildCornerMarkers(
    double screenWidth,
    double screenHeight,
    double ovalWidth,
    double ovalHeight,
    Color color,
  ) {
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;
    final cornerSize = 20.0;
    final strokeWidth = 3.0;

    final positions = [
      // Top left
      Offset(centerX - ovalWidth / 2 - 5, centerY - ovalHeight / 2 - 5),
      // Top right
      Offset(centerX + ovalWidth / 2 - cornerSize + 5, centerY - ovalHeight / 2 - 5),
      // Bottom left
      Offset(centerX - ovalWidth / 2 - 5, centerY + ovalHeight / 2 - cornerSize + 5),
      // Bottom right
      Offset(centerX + ovalWidth / 2 - cornerSize + 5, centerY + ovalHeight / 2 - cornerSize + 5),
    ];

    final corners = [
      [true, true, false, false],   // Top left
      [true, false, false, true],   // Top right
      [false, true, true, false],   // Bottom left
      [false, false, true, true],   // Bottom right
    ];

    return List.generate(4, (index) {
      return Positioned(
        left: positions[index].dx,
        top: positions[index].dy,
        child: CustomPaint(
          size: Size(cornerSize, cornerSize),
          painter: CornerPainter(
            color: color,
            strokeWidth: strokeWidth,
            topLeft: corners[index][0],
            topRight: corners[index][1],
            bottomLeft: corners[index][2],
            bottomRight: corners[index][3],
          ),
        ),
      );
    });
  }
}

class OvalCutoutPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final Color overlayColor;

  OvalCutoutPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: ovalWidth,
        height: ovalHeight,
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Background track
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawOval(rect, bgPaint);

    // Progress arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (topLeft) {
      path.moveTo(0, size.height * 0.4);
      path.lineTo(0, 0);
      path.lineTo(size.width * 0.4, 0);
    }
    if (topRight) {
      path.moveTo(size.width * 0.6, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height * 0.4);
    }
    if (bottomLeft) {
      path.moveTo(0, size.height * 0.6);
      path.lineTo(0, size.height);
      path.lineTo(size.width * 0.4, size.height);
    }
    if (bottomRight) {
      path.moveTo(size.width * 0.6, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height * 0.6);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

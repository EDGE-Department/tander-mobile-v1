import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';

/// First-time tutorial shown before starting liveness and ID scan.
class LivenessTutorialContent extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback? onBack;

  const LivenessTutorialContent({
    super.key,
    required this.onStart,
    this.onBack,
  });

  @override
  State<LivenessTutorialContent> createState() =>
      _LivenessTutorialContentState();
}

class _LivenessTutorialContentState extends State<LivenessTutorialContent>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _hintSlide;
  late final Animation<double> _hintFade;
  late final Animation<Offset> _btnSlide;
  late final Animation<double> _btnFade;
  late final Animation<double> _float;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _iconScale = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );
    _iconFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    );
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
    );
    _hintSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _hintFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
    );
    _btnSlide =
        Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _btnFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );
    _float = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mq = MediaQuery.maybeOf(context);
      final reduceMotion = (mq?.disableAnimations ?? false) ||
          (mq?.accessibleNavigation ?? false);
      if (reduceMotion) {
        _enterCtrl.value = 1;
      } else {
        _enterCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(child: _content()),
                _startButton(),
              ],
            ),
            if (widget.onBack != null)
              Positioned(
                top: 12,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onBack!();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEEFF2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsBold.arrowLeft,
                      color: Color(0xFF141A28),
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          // Floating icon with glow
          ScaleTransition(
            scale: _iconScale,
            child: FadeTransition(
              opacity: _iconFade,
              child: AnimatedBuilder(
                animation: Listenable.merge([_floatCtrl, _glowCtrl]),
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _float.value),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x1A5BBFB3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5BBFB3)
                                .withValues(alpha: _glow.value),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        PhosphorIconsDuotone.user,
                        size: 40,
                        color: Color(0xFF5BBFB3),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          // Title
          SlideTransition(
            position: _titleSlide,
            child: FadeTransition(
              opacity: _titleFade,
              child: const Text(
                'Ready to verify',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF141A28),
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Subtitle
          SlideTransition(
            position: _subtitleSlide,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: const Text(
                'Grab your physical ID and make sure\nyou are in a well-lit space.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF747E93),
                  height: 1.55,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Hint rows
          SlideTransition(
            position: _hintSlide,
            child: FadeTransition(
              opacity: _hintFade,
              child: Column(
                children: [
                  _hintRow(
                    PhosphorIconsDuotone.camera,
                    const Color(0xFFFF8266),
                    'Look at the camera — we\'ll capture automatically',
                  ),
                  const SizedBox(height: 12),
                  _hintRow(
                    PhosphorIconsDuotone.creditCard,
                    const Color(0xFF5BBFB3),
                    'Place your ID in the frame — we\'ll read it for you',
                  ),
                  const SizedBox(height: 12),
                  _hintRow(
                    PhosphorIconsDuotone.lock,
                    const Color(0xFF5BBFB3),
                    'Your info stays private and encrypted',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintRow(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4A5568),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _startButton() {
    return SlideTransition(
      position: _btnSlide,
      child: FadeTransition(
        opacity: _btnFade,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onStart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                elevation: 6,
                shadowColor: const Color(0x4D5BBFB3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Start Verification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

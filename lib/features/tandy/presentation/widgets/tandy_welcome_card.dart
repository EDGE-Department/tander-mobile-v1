import 'dart:async';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Cycling motivational message carousel with auto-advance,
/// progress dots, and cross-fade animation.
class TandyWelcomeCard extends StatefulWidget {
  const TandyWelcomeCard({super.key});

  @override
  State<TandyWelcomeCard> createState() => _TandyWelcomeCardState();
}

class _TandyWelcomeCardState extends State<TandyWelcomeCard> {
  int _activeIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      setState(() {
        _activeIndex = (_activeIndex + 1) % kDailyMessages.length;
      });
    });
  }

  void _goToIndex(int index) {
    if (index == _activeIndex) return;
    _timer?.cancel();
    setState(() => _activeIndex = index);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final message = kDailyMessages[_activeIndex];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1DC)),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Top accent
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[message.accentColor, message.accentColor.withAlpha(136)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Eyebrow row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(colors: <Color>[Color(0xFFFEF0E0), Color(0xFFFDDCB0)]),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 14, color: kTandyOrange),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "TODAY'S MESSAGE",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    // Navigation dots
                    Row(
                      children: List.generate(kDailyMessages.length, (index) {
                        final isActive = index == _activeIndex;
                        return GestureDetector(
                          onTap: () => _goToIndex(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 18 : 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: isActive ? message.accentColor : const Color(0x669CA3AF),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message body
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    message.text,
                    key: ValueKey(message.id),
                    style: const TextStyle(fontSize: 17, height: 1.75, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE5E1DC)),
                const SizedBox(height: 8),

                // Byline
                Row(
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 22, height: 2.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(colors: <Color>[message.accentColor, message.accentColor.withAlpha(136)]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Tandy, your wellness companion',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
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

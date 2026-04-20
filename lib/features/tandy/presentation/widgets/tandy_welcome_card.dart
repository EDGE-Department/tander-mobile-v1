import 'dart:async';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Simple motivational message card with auto-cycling.
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
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      setState(() => _activeIndex = (_activeIndex + 1) % kDailyMessages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          Container(
            height: 3,
            color: message.accentColor,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                message.text,
                key: ValueKey(message.id),
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

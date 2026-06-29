import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/id_scanner_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_bottom_bar.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_hero.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_steps_card.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_tips_card.dart';

/// Ready-to-verify step — hero + overlapping steps card. Forked off the shared
/// auth scaffold for a bespoke layout; route + nav are unchanged.
class ReadyToVerifyScreen extends StatelessWidget {
  const ReadyToVerifyScreen({super.key});

  void _onBack(BuildContext context) {
    if (context.canPop()) context.pop();
  }

  void _onStart(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const IdScannerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Task 6 wires the >=1024 two-pane branch.
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: _SingleColumn(
        maxWidth: width >= 768 ? 560 : double.infinity,
        onBack: () => _onBack(context),
        onStart: () => _onStart(context),
      ),
    );
  }
}

class _SingleColumn extends StatelessWidget {
  const _SingleColumn({
    required this.maxWidth, required this.onBack, required this.onStart,
  });
  final double maxWidth;
  final VoidCallback onBack;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    VerifyHero(onBack: onBack),
                    // Overlap as a real layout offset: shift the lower group up.
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Column(
                          children: [
                            VerifyStepsCard(),
                            SizedBox(height: 12),
                            VerifyTipsCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerifyBottomBar(onStart: onStart),
          ],
        ),
      ),
    );
  }
}

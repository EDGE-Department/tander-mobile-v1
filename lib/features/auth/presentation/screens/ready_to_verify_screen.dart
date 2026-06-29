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
    // heroHeight: SafeArea top inset (device notch) + 184px for content at
    // 1.3× text scale with slack. This value must not be const — it reads the
    // MediaQuery so it handles notched devices correctly.
    final heroHeight = MediaQuery.paddingOf(context).top + 184.0;
    const overlapPx = 24.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Layout-correct overlap:
                    // • SizedBox is (heroHeight - overlapPx) tall — this is the
                    //   hero's contribution to the column's layout height.
                    // • OverflowBox forces the hero to paint at its full
                    //   heroHeight aligned to the top, so the bottom 24px bleeds
                    //   into the next child's space (not clipped by OverflowBox).
                    // • The steps card is the next Column child, so it paints ON
                    //   TOP of the hero at the seam — correct z-order.
                    // • No Transform.translate → no trailing dead space.
                    SizedBox(
                      height: heroHeight - overlapPx,
                      child: OverflowBox(
                        minHeight: heroHeight,
                        maxHeight: heroHeight,
                        alignment: Alignment.topCenter,
                        child: VerifyHero(height: heroHeight, onBack: onBack),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        children: [
                          VerifyStepsCard(),
                          SizedBox(height: 12),
                          VerifyTipsCard(),
                        ],
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/id_scanner_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_bottom_bar.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_hero.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_safety_content.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_safety_panel.dart';
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

    // Tablet-landscape two-pane layout (>= 1024 dp wide).
    if (width >= 1024) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Row(
          children: [
            Expanded(
              flex: 60,
              child: _SingleColumn(
                onBack: () => _onBack(context),
                onStart: () => _onStart(context),
              ),
            ),
            const Expanded(
              flex: 40,
              child: ColoredBox(
                color: Color(0xFFF4F8F4),
                child: VerifySafetyPanel(),
              ),
            ),
          ],
        ),
      );
    }

    // Tablet-portrait layout (768–1023 dp wide): wider content + safety content.
    if (width >= 768) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: _SingleColumn(
          extra: const VerifySafetyContent(),
          onBack: () => _onBack(context),
          onStart: () => _onStart(context),
        ),
      );
    }

    // Phone layout (< 768 dp wide): lean single column, no extra content.
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: _SingleColumn(
        onBack: () => _onBack(context),
        onStart: () => _onStart(context),
      ),
    );
  }
}

class _SingleColumn extends StatelessWidget {
  const _SingleColumn({
    required this.onBack,
    required this.onStart,
    this.extra,
  });
  final VoidCallback onBack;
  final VoidCallback onStart;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    // heroHeight: SafeArea top inset (device notch) + 184px for content at
    // 1.3× text scale with slack. This value must not be const — it reads the
    // MediaQuery so it handles notched devices correctly.
    final heroHeight = MediaQuery.paddingOf(context).top + 184.0;
    const overlapPx = 24.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      const VerifyStepsCard(),
                      const SizedBox(height: 12),
                      const VerifyTipsCard(),
                      if (extra != null) ...[
                        const SizedBox(height: 24),
                        extra!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        VerifyBottomBar(onStart: onStart),
      ],
    );
  }
}

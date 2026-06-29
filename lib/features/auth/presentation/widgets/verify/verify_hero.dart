import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';

/// Smoother orange→green hero gradient, scoped to the verify screen.
/// Bridges the muddy midpoint with a warm-amber + yellow-green stop.
const LinearGradient verifyHeroGradient = LinearGradient(
  begin: Alignment(-1, -1),
  end: Alignment(1, 1),
  colors: [
    Color(0xFFF0703E), Color(0xFFE2924F), Color(0xFF9FB85E),
    Color(0xFF46C07F), Color(0xFF1FBF67),
  ],
  stops: [0.0, 0.36, 0.56, 0.78, 1.0],
);

class VerifyHero extends StatelessWidget {
  const VerifyHero({required this.onBack, this.height, super.key});
  final VoidCallback onBack;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: verifyHeroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: AuthHeaderScene())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'Go back',
                        child: InkResponse(
                          onTap: onBack,
                          radius: 28,
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Image.asset('assets/icons/tander_icon.png',
                      width: 48, height: 48, semanticLabel: 'Tander logo'),
                  const SizedBox(height: 4),
                  Text('Tander',
                      style: AppTypography.brandWordmark(
                          fontSize: 24, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

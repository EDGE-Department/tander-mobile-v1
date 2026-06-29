import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Reusable inner content of the safety panel: illustration + headline +
/// three trust points. Contains NO scroll wrapper and NO outer padding so
/// it can be embedded in any parent (panel or single-column scroll).
class VerifySafetyContent extends StatelessWidget {
  const VerifySafetyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            'assets/images/verify_safety_illustration.png',
            width: 260,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) =>
                const _IllustrationFallback(),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Simple steps for your safety',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'We make sure your identity is real so our community stays safe and trusted.',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        _trust(Icons.lock_outline, 'Secure',
            'Your data is encrypted and never shared.'),
        _trust(Icons.verified_user_outlined, 'Trusted',
            'We follow strict guidelines to protect you.'),
        _trust(Icons.groups_outlined, 'Community Safe',
            'Verified members build a better community.'),
      ],
    );
  }

  static Widget _trust(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF0F6E56)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vector fallback rendered when the PNG asset is not yet present.
/// Approximates the safety illustration: an ID card alongside a verified
/// shield, with a few sparkle accents.
class _IllustrationFallback extends StatelessWidget {
  const _IllustrationFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ID card
          Positioned(
            left: 8,
            top: 20,
            child: Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF81C784), width: 1.5),
              ),
              child: Row(
                children: [
                  // Person avatar area
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5D6A7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  // Text lines
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBDBDBD),
                                borderRadius: BorderRadius.circular(4),
                              )),
                          Container(
                              height: 8,
                              width: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBDBDBD),
                                borderRadius: BorderRadius.circular(4),
                              )),
                          Container(
                              height: 8,
                              width: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBDBDBD),
                                borderRadius: BorderRadius.circular(4),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Verified shield badge
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFF1FBF67),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 38,
                color: Colors.white,
              ),
            ),
          ),
          // Sparkle accents
          const Positioned(
            top: 8,
            right: 50,
            child: Icon(Icons.star, size: 12, color: Color(0xFFF9A825)),
          ),
          const Positioned(
            top: 30,
            right: 20,
            child: Icon(Icons.star, size: 8, color: Color(0xFF81C784)),
          ),
          const Positioned(
            bottom: 30,
            left: 20,
            child: Icon(Icons.star, size: 10, color: Color(0xFFFFF176)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Two stacked consent rows styled to match the preferred web treatment.
class AgreementCheckboxes extends StatelessWidget {
  final bool agreedToTerms;
  final bool agreedToPrivacy;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final VoidCallback onTermsTapped;
  final VoidCallback onPrivacyTapped;

  const AgreementCheckboxes({
    super.key,
    required this.agreedToTerms,
    required this.agreedToPrivacy,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onTermsTapped,
    required this.onPrivacyTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAE7E2), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CheckboxRow(
            isChecked: agreedToTerms,
            onChanged: () => onTermsChanged(!agreedToTerms),
            label: 'I agree to the ',
            linkText: 'Terms & Conditions',
            onLinkTapped: onTermsTapped,
          ),
          const SizedBox(height: 16),
          _CheckboxRow(
            isChecked: agreedToPrivacy,
            onChanged: () => onPrivacyChanged(!agreedToPrivacy),
            label: 'I agree to the ',
            linkText: 'Data Privacy Policy',
            onLinkTapped: onPrivacyTapped,
          ),
        ],
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.isChecked,
    required this.onChanged,
    required this.label,
    required this.linkText,
    required this.onLinkTapped,
  });

  final bool isChecked;
  final VoidCallback onChanged;
  final String label;
  final String linkText;
  final VoidCallback onLinkTapped;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFFE67E22) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isChecked
                    ? const Color(0xFFE67E22)
                    : const Color(0xFFD9D3C8),
                width: 1.4,
              ),
            ),
            child: isChecked
                ? CustomPaint(
                    size: const Size(12, 10),
                    painter: _CheckPainter(),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                  height: 1.35,
                ),
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: linkText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF1F2937),
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onLinkTapped,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.82, size.height * 0.24);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

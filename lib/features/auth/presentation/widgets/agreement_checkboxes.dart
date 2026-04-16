import 'package:flutter/material.dart';

/// Two checkboxes for Terms & Conditions and Data Privacy Policy.
///
/// Teal checkbox for terms, orange for privacy — matching web's
/// `<AgreementCheckboxes>` component pixel-for-pixel.
///
/// Web specs: 20x20 checkbox, rounded-[5px], border-[1.5px],
/// unchecked border rgba(160,130,90,0.30), 13px text, gap-2.5.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CheckboxRow(
          isChecked: agreedToTerms,
          onChanged: () => onTermsChanged(!agreedToTerms),
          checkedColor: const Color(0xFF0D9488),
          label: 'I agree to the ',
          linkText: 'Terms & Conditions',
          linkColor: const Color(0xFF0F766E),
          onLinkTapped: onTermsTapped,
        ),
        const SizedBox(height: 2),
        _CheckboxRow(
          isChecked: agreedToPrivacy,
          onChanged: () => onPrivacyChanged(!agreedToPrivacy),
          checkedColor: const Color(0xFFE67E22),
          label: 'I agree to the ',
          linkText: 'Data Privacy Policy',
          linkColor: const Color(0xFFC96D18),
          onLinkTapped: onPrivacyTapped,
        ),
      ],
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onChanged;
  final Color checkedColor;
  final String label;
  final String linkText;
  final Color linkColor;
  final VoidCallback onLinkTapped;

  const _CheckboxRow({
    required this.isChecked,
    required this.onChanged,
    required this.checkedColor,
    required this.label,
    required this.linkText,
    required this.linkColor,
    required this.onLinkTapped,
  });

  /// Unchecked border: web rgba(160,130,90,0.30).
  static const Color _uncheckedBorder = Color(0x4DA0825A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // web: px-1 py-1 — compact for mobile
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // web: w-[20px] h-[20px] rounded-[5px] border-[1.5px]
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? checkedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? checkedColor : _uncheckedBorder,
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? CustomPaint(
                      size: const Size(11, 9),
                      painter: _CheckPainter(),
                    )
                  : null,
            ),
            const SizedBox(width: 8), // web: gap-2.5
            Expanded(
              // web: text-[13px] text-text-body
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF374151),
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: label),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: onLinkTapped,
                        child: Text(
                          linkText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: linkColor,
                            decoration: TextDecoration.underline,
                            decorationColor: linkColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the web's SVG checkmark: M1 4L4 7L10 1, strokeWidth 2.
class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.09, size.height * 0.44)
      ..lineTo(size.width * 0.36, size.height * 0.78)
      ..lineTo(size.width * 0.91, size.height * 0.11);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

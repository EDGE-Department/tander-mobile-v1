import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';

class VerifyTipsCard extends StatefulWidget {
  const VerifyTipsCard({super.key});
  @override
  State<VerifyTipsCard> createState() => _VerifyTipsCardState();
}

class _VerifyTipsCardState extends State<VerifyTipsCard> {
  bool _open = false;
  static const _tips = [
    'Find good lighting',
    'Lay your ID flat on a dark surface',
    'Avoid glare and shadows',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF5BBFB3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          initiallyExpanded: false,
          onExpansionChanged: (v) => setState(() => _open = v),
          leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF3E9B90)),
          title: const Text('Tips for a clear photo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
          trailing: Icon(_open ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF3E9B90)),
          children: [
            for (final t in _tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_rounded, size: 18, color: Color(0xFF3E9B90))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: const TextStyle(
                      fontSize: 15, height: 1.35, color: AppColors.textBody))),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

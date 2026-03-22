import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// 3-column emoji mood selector grid.
///
/// After selection, the chosen mood scales up and highlights,
/// then fires the callback with the mood's chat message.
class TandyMoodCheckin extends StatefulWidget {
  const TandyMoodCheckin({required this.onMoodSelect, super.key});

  final void Function(String chatMessage) onMoodSelect;

  @override
  State<TandyMoodCheckin> createState() => _TandyMoodCheckinState();
}

class _TandyMoodCheckinState extends State<TandyMoodCheckin> {
  String? _selectedId;

  void _handleSelect(MoodOption mood) {
    if (_selectedId != null) return;
    setState(() => _selectedId = mood.id);
    Future.delayed(const Duration(milliseconds: 420), () {
      widget.onMoodSelect(mood.chatMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'HOW ARE YOU FEELING?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Color(0xFF9A9080),
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: kMoodOptions.map((mood) {
            final isSelected = _selectedId == mood.id;
            final isDisabled = _selectedId != null && !isSelected;

            return AnimatedScale(
              scale: isSelected ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 240),
              child: AnimatedOpacity(
                opacity: isDisabled ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 240),
                child: Material(
                  color: isSelected ? mood.accentColor : mood.accentColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isDisabled ? null : () => _handleSelect(mood),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? mood.accentColor : mood.accentColor.withAlpha(56),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? <BoxShadow>[BoxShadow(color: mood.accentColor.withAlpha(66), blurRadius: 24, offset: const Offset(0, 8))]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(mood.emoji, style: const TextStyle(fontSize: 34)),
                          const SizedBox(height: 6),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white.withAlpha(245) : mood.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

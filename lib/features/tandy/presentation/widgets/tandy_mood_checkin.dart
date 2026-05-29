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
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: kMoodOptions.map((mood) {
        final isSelected = _selectedId == mood.id;
        final isDisabled = _selectedId != null && !isSelected;

        return AnimatedOpacity(
          opacity: isDisabled ? 0.3 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: isSelected
                ? mood.accentColor
                : mood.accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: isDisabled ? null : () => _handleSelect(mood),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? mood.accentColor
                        : mood.accentColor.withAlpha(60),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(mood.emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 6),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : mood.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

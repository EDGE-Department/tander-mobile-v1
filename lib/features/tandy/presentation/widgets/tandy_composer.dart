import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Chat input composer with prompt suggestion chips and send button.
class TandyComposer extends StatelessWidget {
  const TandyComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.showSuggestions,
    required this.suggestions,
    required this.onSend,
    required this.onSuggestionTap,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool showSuggestions;
  final List<String> suggestions;
  final VoidCallback onSend;
  final void Function(String suggestion) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.canvas.withAlpha(0),
            AppColors.canvas.withAlpha(245),
            AppColors.canvas,
          ],
        ),
        border: const Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kThreadMaxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showSuggestions && suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length.clamp(0, 3),
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final suggestion = suggestions[index];
                          return _PromptChip(
                            label: suggestion,
                            onTap: () => onSuggestionTap(suggestion),
                          );
                        },
                      ),
                    ),
                  ),

                // Input row
                _InputRow(
                  controller: controller,
                  focusNode: focusNode,
                  isSending: isSending,
                  onSend: onSend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Prompt Chip ─────────────────────────────────────────────────────

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C5044),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input Row ───────────────────────────────────────────────────────

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, textValue, __) {
        final canSend = textValue.text.trim().isNotEmpty && !isSending;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F5),
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(20, 6, 6, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message Tandy...',
                    hintStyle: TextStyle(
                      color: Color(0xFFADA9A4),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(
                canSend: canSend,
                isSending: isSending,
                onSend: onSend,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: canSend ? kTandyOrange : const Color(0xFFE8E5E1),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: canSend ? onSend : null,
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.arrow_upward_rounded,
                    size: 22,
                    color: canSend ? Colors.white : const Color(0xFFB8B4AF),
                  ),
          ),
        ),
      ),
    );
  }
}

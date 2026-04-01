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
                // Suggestion chips
                if (showSuggestions && suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestions.length.clamp(0, 4),
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
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
      color: Colors.white.withAlpha(217),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.borderLight.withAlpha(204),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
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
            color: Colors.white.withAlpha(245),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderLight.withAlpha(204)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A101828),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
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
                    hintText: "Share what's on your mind\u2026",
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15.5,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 15.5,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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

// ── Send Button ─────────────────────────────────────────────────────

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
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: canSend
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[kTandyOrange, Color(0xFFC96D18)],
              )
            : null,
        color: canSend ? null : const Color(0xB3F0ECE6),
        boxShadow: canSend
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x47E67E22),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canSend ? onSend : null,
          child: Center(
            child: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: canSend ? Colors.white : const Color(0xFFC0B8B2),
                  ),
          ),
        ),
      ),
    );
  }
}

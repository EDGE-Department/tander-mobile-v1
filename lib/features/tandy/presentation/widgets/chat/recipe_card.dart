import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Expandable recipe card rendered inside Tandy chat bubbles.
///
/// Features a top gradient accent, stats bar, ingredient checklist,
/// step timeline with timer badges, and a "Start Cooking Mode" CTA.
class RecipeCardWidget extends StatefulWidget {
  const RecipeCardWidget({
    required this.recipeData,
    required this.title,
    required this.isExpanded,
    super.key,
  });

  final RecipeBlockData recipeData;
  final String title;
  final bool isExpanded;

  @override
  State<RecipeCardWidget> createState() => _RecipeCardWidgetState();
}

class _RecipeCardWidgetState extends State<RecipeCardWidget> {
  late bool _isExpanded;
  final Set<int> _checkedIngredients = <int>{};

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final recipeData = widget.recipeData;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3DA)),
        color: Colors.white,
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0FE67E22), blurRadius: 16),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Top accent bar
          Container(height: 4, color: kTandyOrange),

          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[kTandyOrange, Color(0xFFD35400)],
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2A26),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF9B8F80),
                  ),
                ],
              ),
            ),
          ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0EDE7))),
              color: Color(0x05E67E22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _StatColumn(label: 'Prep', value: recipeData.prepTime ?? '--'),
                Container(width: 1, height: 32, color: const Color(0xFFE8E3DA)),
                _StatColumn(
                  label: 'Calories',
                  value: recipeData.calories.toString(),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE8E3DA)),
                _StatColumn(
                  label: 'Serves',
                  value: recipeData.servings.toString(),
                ),
              ],
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedContent(
              recipeData: recipeData,
              checkedIngredients: _checkedIngredients,
              onToggleIngredient: (index) {
                setState(() {
                  if (_checkedIngredients.contains(index)) {
                    _checkedIngredients.remove(index);
                  } else {
                    _checkedIngredients.add(index);
                  }
                });
              },
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D2A26),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF9B8F80)),
        ),
      ],
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.recipeData,
    required this.checkedIngredients,
    required this.onToggleIngredient,
  });

  final RecipeBlockData recipeData;
  final Set<int> checkedIngredients;
  final void Function(int index) onToggleIngredient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Ingredients
          const _SectionHeader(label: 'Ingredients'),
          ...List.generate(recipeData.ingredients.length, (index) {
            final isChecked = checkedIngredients.contains(index);
            return InkWell(
              onTap: () => onToggleIngredient(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isChecked
                              ? kTandyOrange
                              : const Color(0xFFD5CFC4),
                          width: 2,
                        ),
                        color: isChecked ? kTandyOrange : Colors.transparent,
                      ),
                      child: isChecked
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recipeData.ingredients[index],
                        style: TextStyle(
                          fontSize: 15,
                          color: isChecked
                              ? const Color(0xFF9B8F80)
                              : const Color(0xFF2D2A26),
                          decoration: isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: kTandyOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Instructions
          const _SectionHeader(label: 'Instructions'),
          ...recipeData.instructions.asMap().entries.map((entry) {
            final instruction = entry.value;
            final isLast = entry.key == recipeData.instructions.length - 1;
            return _InstructionStep(instruction: instruction, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: <Color>[kTandyOrange, Color(0xFFD35400)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2A26),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.instruction, required this.isLast});

  final RecipeInstruction instruction;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: <Color>[kTandyOrange, Color(0xFFD35400)],
                ),
              ),
              child: Center(
                child: Text(
                  instruction.stepNumber.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFE8E3DA),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  instruction.text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D2A26),
                    height: 1.6,
                  ),
                ),
                if (instruction.timerDurationMinutes != null &&
                    instruction.timerDurationMinutes! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFFFEF0E0), Color(0xFFFDDCB0)],
                        ),
                      ),
                      child: Text(
                        '${instruction.timerDurationMinutes} min',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

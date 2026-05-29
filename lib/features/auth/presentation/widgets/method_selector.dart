import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/features/auth/data/registration_method.dart';

/// Login button gradient matching web: from-[#E67E22] to-[#D35400]
const LinearGradient _toggleGradient = LinearGradient(
  colors: [Color(0xFFE67E22), Color(0xFFD35400)],
);

/// Animated segmented control for Phone | Email registration.
///
/// Orange slider animates between the two options. 56px height,
/// elder-friendly touch targets.
class MethodSelector extends StatefulWidget {
  final RegistrationMethod selected;
  final ValueChanged<RegistrationMethod> onChanged;
  final bool enabled;

  const MethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<MethodSelector> createState() => _MethodSelectorState();
}

class _MethodSelectorState extends State<MethodSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    // Driving is gated in build() on MediaQuery.disableAnimationsOf, which is
    // unavailable here in initState.
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = widget.selected == RegistrationMethod.phone;
    // Vestibular accessibility: when reduce-motion is on, render the static
    // (non-shimmering) slider and stop driving the continuous shimmer.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_shimmerController.isAnimating) _shimmerController.stop();
    } else if (!_shimmerController.isAnimating) {
      _shimmerController.repeat();
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Animated slider with shimmer
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isPhone
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: widget.enabled ? _toggleGradient : null,
                    color: widget.enabled ? null : const Color(0xFF9CA3AF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: widget.enabled
                        ? const [
                            BoxShadow(
                              color: Color(0x59E67E22),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                              spreadRadius: -4,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // Reduce-motion: omit the moving white-sweep highlight and
                    // show the plain (static) slider.
                    child: reduceMotion
                        ? const SizedBox.expand()
                        : AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (_, _) {
                              final translateX =
                                  (_shimmerController.value * 3.0 - 1.0);
                              return Transform.translate(
                                offset: Offset(translateX * tabWidth, 0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0x00FFFFFF),
                                        Color(0x30FFFFFF),
                                        Color(0x00FFFFFF),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              // Tabs
              Row(
                children: [
                  _Tab(
                    icon: PhosphorIconsRegular.phone,
                    label: 'Phone',
                    isSelected: isPhone,
                    onTap: widget.enabled
                        ? () {
                            if (!isPhone) {
                              HapticFeedback.selectionClick();
                              widget.onChanged(RegistrationMethod.phone);
                            }
                          }
                        : null,
                  ),
                  _Tab(
                    icon: PhosphorIconsRegular.envelope,
                    label: 'Email',
                    isSelected: !isPhone,
                    onTap: widget.enabled
                        ? () {
                            if (isPhone) {
                              HapticFeedback.selectionClick();
                              widget.onChanged(RegistrationMethod.email);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : const Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

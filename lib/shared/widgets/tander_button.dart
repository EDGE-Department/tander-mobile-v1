import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Visual variant for [TanderButton].
enum TanderButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  danger,
  iconOnly,
}

/// Size preset for [TanderButton].
enum TanderButtonSize {
  /// 40 px minimum height.
  compact,

  /// 56 px minimum height — elder-friendly default.
  normal,

  /// 64 px minimum height.
  large,
}

/// Position of the optional icon relative to the label.
enum IconPosition { leading, trailing }

/// Elder-friendly button matching the Tander web BTN token system.
///
/// Six visual [variant]s, three [size]s, optional [icon], and built-in
/// loading / disabled states with scale-down press feedback.
class TanderButton extends StatefulWidget {
  const TanderButton({
    required this.label,
    required this.onPressed,
    this.variant = TanderButtonVariant.primary,
    this.size = TanderButtonSize.normal,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconPosition = IconPosition.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TanderButtonVariant variant;
  final TanderButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final IconPosition iconPosition;

  @override
  State<TanderButton> createState() => _TanderButtonState();
}

class _TanderButtonState extends State<TanderButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isInteractive =>
      !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (_isInteractive) _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == TanderButtonVariant.iconOnly) {
      return _buildIconOnlyButton();
    }

    final specs = _VariantSpecs.resolve(widget.variant);
    final double minHeight = _resolveMinHeight();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Opacity(
        opacity: widget.isDisabled ? 0.5 : 1.0,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _isInteractive ? widget.onPressed : null,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: BoxDecoration(
              gradient: specs.gradient,
              color: specs.gradient == null ? specs.backgroundColor : null,
              // Web: rounded-[20px]
              borderRadius: BorderRadius.circular(20),
              border: specs.borderSide != null
                  ? Border.all(
                      color: specs.borderSide!.color,
                      width: specs.borderSide!.width,
                    )
                  : null,
              boxShadow: specs.boxShadow,
            ),
            padding: _resolvePadding(),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildChildren(specs),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Opacity(
        opacity: widget.isDisabled ? 0.5 : 1.0,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _isInteractive ? widget.onPressed : null,
          child: SizedBox(
            width: AppSpacing.touchMinimum,
            height: AppSpacing.touchMinimum,
            child: Center(
              child: widget.isLoading
                  ? _buildLoader(AppColors.primary)
                  : Icon(
                      widget.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(_VariantSpecs specs) {
    if (widget.isLoading) {
      return [_buildLoader(specs.foregroundColor)];
    }

    // Wrap in Flexible so the row's `mainAxisSize: min` doesn't let the
    // label paint past the button's right edge — without Flexible the
    // built-in ellipsis never fires (the Text widget renders at intrinsic
    // width + the row's min-sizing has nowhere to clip).
    final label = Flexible(
      child: Text(
        widget.label.toUpperCase(),
        style: _resolveLabelStyle(specs.foregroundColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );

    if (widget.icon == null) return [label];

    final iconWidget = Icon(
      widget.icon,
      size: 20,
      color: specs.foregroundColor,
    );
    const gap = SizedBox(width: AppSpacing.xs);

    return widget.iconPosition == IconPosition.leading
        ? [iconWidget, gap, label]
        : [label, gap, iconWidget];
  }

  Widget _buildLoader(Color color) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  TextStyle _resolveLabelStyle(Color color) {
    final baseStyle = switch (widget.size) {
      TanderButtonSize.compact => AppTypography.label,
      TanderButtonSize.normal => AppTypography.body,
      TanderButtonSize.large => AppTypography.bodyLg,
    };
    // Web: font-black uppercase tracking-[0.12em]
    return baseStyle.copyWith(
      color: color,
      fontWeight: FontWeight.w900,
      height: 1.0,
      letterSpacing: 0.12 * 16,
    );
  }

  double _resolveMinHeight() {
    return switch (widget.size) {
      TanderButtonSize.compact => 40,
      // Web: h-[60px]
      TanderButtonSize.normal => 60,
      TanderButtonSize.large => 64,
    };
  }

  EdgeInsets _resolvePadding() {
    return switch (widget.size) {
      TanderButtonSize.compact =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      TanderButtonSize.normal =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      TanderButtonSize.large =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
    };
  }
}

/// Resolved visual properties for each [TanderButtonVariant].
class _VariantSpecs {
  const _VariantSpecs({
    required this.foregroundColor,
    this.backgroundColor,
    this.gradient,
    this.borderSide,
    this.boxShadow,
  });

  final Color foregroundColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BorderSide? borderSide;
  final List<BoxShadow>? boxShadow;

  // Web: bg-gradient-to-r from-[#E67E22] to-[#D35400]
  static const _primaryGradient = LinearGradient(
    colors: [Color(0xFFE67E22), Color(0xFFD35400)],
  );

  // Web: shadow-[0_20px_40px_-12px_rgba(230,126,34,0.35)]
  static const _primaryShadow = [
    BoxShadow(
      color: Color(0x59E67E22),
      blurRadius: 40,
      offset: Offset(0, 20),
      spreadRadius: -12,
    ),
  ];

  static _VariantSpecs resolve(TanderButtonVariant variant) {
    return switch (variant) {
      TanderButtonVariant.primary => const _VariantSpecs(
            foregroundColor: AppColors.textInverse,
            gradient: _primaryGradient,
            boxShadow: _primaryShadow,
          ),
      TanderButtonVariant.secondary => const _VariantSpecs(
            foregroundColor: AppColors.textInverse,
            backgroundColor: AppColors.secondary,
          ),
      TanderButtonVariant.outline => const _VariantSpecs(
            foregroundColor: AppColors.primary,
            backgroundColor: Color(0x00000000),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
      TanderButtonVariant.ghost => const _VariantSpecs(
            foregroundColor: AppColors.primary,
            backgroundColor: Color(0x00000000),
          ),
      TanderButtonVariant.danger => const _VariantSpecs(
            foregroundColor: AppColors.textInverse,
            backgroundColor: AppColors.danger,
          ),
      TanderButtonVariant.iconOnly => const _VariantSpecs(
            foregroundColor: AppColors.primary,
            backgroundColor: Color(0x00000000),
          ),
    };
  }
}

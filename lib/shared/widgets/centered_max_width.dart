/// Centers and width-clamps content on wide (tablet / landscape) surfaces.
library;

import 'package:flutter/widgets.dart';

/// Horizontally centers [child] and clamps it to [maxWidth].
///
/// On phones the surface is already narrower than any [maxWidth] we use, so
/// this is a visual no-op there — only tablet/landscape layouts are affected,
/// where it stops feed/list/form content from stretching edge-to-edge into
/// 80+ character line lengths (a readability problem for the 60+ audience).
///
/// Layout: `Align(alignment) -> ConstrainedBox(maxWidth) -> [padding] -> child`.
///
/// PLACEMENT CONTRACT: render this in a BOUNDED-HEIGHT slot — a `Scaffold`
/// body, an `Expanded`, or a panel that fills its parent. Wrap the SCROLL VIEW
/// (`ListView` / `SingleChildScrollView` / `CustomScrollView`), not a `Column`
/// nested inside one; the [Align] needs a finite height to lay out against.
class CenteredMaxWidth extends StatelessWidget {
  const CenteredMaxWidth({
    required this.maxWidth,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  /// Maximum logical width the [child] may occupy.
  final double maxWidth;

  /// The constrained, centered content. Typically a scroll view.
  final Widget child;

  /// Optional padding applied inside the width clamp (counts toward [maxWidth]).
  final EdgeInsetsGeometry? padding;

  /// How the clamped box sits within the available space. Defaults to
  /// [Alignment.topCenter]; pass [Alignment.center] to also center vertically.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry? pad = padding;
    Widget content = child;
    if (pad != null) {
      content = Padding(padding: pad, child: content);
    }
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}

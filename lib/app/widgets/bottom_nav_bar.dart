import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_parts.dart';
import 'package:tander_flutter_v3/app/widgets/nav_badge_provider.dart';
import 'package:tander_flutter_v3/app/widgets/nav_geometry.dart';
import 'package:tander_flutter_v3/app/widgets/nav_rail_indicator.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ── Tab descriptors ─────────────────────────────────────────────────────────

// Shared with the tablet/desktop [TanderTopNavBar] — keep the icon fields the
// top nav relies on. Order: Chat · Connect · Discover (centre) · Tandy · Profile.
const List<NavTabDescriptor> navTabs = [
  NavTabDescriptor(
    id: 'messages',
    label: 'Chat',
    route: AppRoutes.messages,
    iconAsset: 'assets/icons/nav/chat-idle.png',
  ),
  NavTabDescriptor(
    id: 'connections',
    label: 'Connect',
    route: AppRoutes.connection,
    iconAsset: 'assets/icons/nav/connect-idle.png',
  ),
  NavTabDescriptor(
    id: 'discover',
    label: 'Discover',
    route: AppRoutes.discover,
    iconAsset: 'assets/icons/nav/discover-idle.png',
  ),
  NavTabDescriptor(
    id: 'tandy',
    label: 'Tandy',
    route: AppRoutes.tandy,
    iconAsset: 'assets/icons/nav/tandy-idle.png',
    isTandy: true,
  ),
  NavTabDescriptor(
    id: 'profile',
    label: 'Profile',
    route: AppRoutes.profile,
    iconAsset: 'assets/icons/nav/profile-idle.png',
  ),
];

/// Real idle / clicked icon asset per tab id.
const Map<String, String> _kIdleIcons = {
  'discover': 'assets/icons/nav/discover-idle.png',
  'connections': 'assets/icons/nav/connect-idle.png',
  'messages': 'assets/icons/nav/chat-idle.png',
  'tandy': 'assets/icons/nav/tandy-idle.png',
  'profile': 'assets/icons/nav/profile-idle.png',
};
const Map<String, String> _kClickedIcons = {
  'discover': 'assets/icons/nav/discover-clicked.png',
  'connections': 'assets/icons/nav/connect-clicked.png',
  'messages': 'assets/icons/nav/chat-clicked.png',
  'tandy': 'assets/icons/nav/tandy-clicked.png',
  'profile': 'assets/icons/nav/profile-clicked.png',
};

/// Glow colour behind the selected icon, per tab id.
const Map<String, Color> _kGlowColors = {
  'discover': Color(0xFF4F9BE8),
  'connections': Color(0xFFE85C97),
  'messages': Color(0xFFE67E22),
  'tandy': Color(0xFF4F9BE8),
  'profile': Color(0xFF8B6BE8),
};

// ── Tunables (Task 7 tunes these on-device) ─────────────────────────────────

// Both the pill and the rail are LOCKED to their PNG aspect ratios so they
// scale proportionally — height is always derived from width, never squashed.
const double _kCapsuleAspect = 241.0 / 1464.0; // nav_capsule.png height / width
const double _kRailAspect = 67.0 / 251.0; // nav_rail.png height / width
const double railMarginFrac = 0.08; // % of pill width clamped on each side
const double _kRailOverlap = 3.0; // px of the rail tucked behind the pill (merge)
const double _kWidthFrac = 0.8; // pill width as a fraction of the screen width

/// Single source of truth for the bar surface colour — shared by the capsule
/// and the rail tint so the white-on-white merge is exact.
const Color _kSurfaceColor = Color(0xFFFFC794);
const Color _kIconActiveColor = Color(0xFFFFE7C5);

// ── Platform-adaptive haptics ────────────────────────────────────────────────
// iOS uses UIImpactFeedbackGenerator (works in silent mode).
// Android uses Vibrator.vibrate(50ms) which is more reliable than performHapticFeedback.

void _hapticLift() => Platform.isIOS
    ? HapticFeedback.lightImpact()
    : HapticFeedback.vibrate();

void _hapticTick() => Platform.isIOS
    ? HapticFeedback.lightImpact()
    : HapticFeedback.vibrate();

void _hapticSelect() => Platform.isIOS
    ? HapticFeedback.mediumImpact()
    : HapticFeedback.vibrate();

// ── TanderBottomNavBar ──────────────────────────────────────────────────────

/// Phone bottom dock: a white capsule + a 5-column segmented layout + a single
/// "rail" indicator that slides to the active column. The rail sits *behind*
/// the capsule, overlapping its top edge by [_kRailOverlap] px so the two white
/// shapes merge into one surface with a traveling hump.
///
/// Phase 1: placeholder boxes stand in for the real icons.
///
/// This is the provider-wiring layer only: it resolves the active tab, badge
/// counts, and reduced-motion, then delegates all layout to [BottomNavBarView]
/// (which is provider-free and therefore directly widget-testable).
class TanderBottomNavBar extends ConsumerWidget {
  const TanderBottomNavBar({super.key});

  static int _badgeForTab(String id, NavBadgeCounts counts) {
    if (id == 'messages') return counts.unreadMessageCount;
    if (id == 'connections') return counts.pendingConnectionCount;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final activeIndex = activeIndexForLocation(location, [
      for (final t in navTabs) t.route,
    ]);
    final badgeCounts = ref.watch(navBadgeProvider);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return BottomNavBarView(
      activeIndex: activeIndex,
      reduceMotion: reduceMotion,
      badgeFor: (id) => _badgeForTab(id, badgeCounts),
      onTap: (index) => context.go(navTabs[index].route),
    );
  }
}

/// Pure presentational bottom dock — no providers, no router. Renders the
/// capsule, the sliding rail, and the 5 placeholder columns from plain inputs.
class BottomNavBarView extends StatefulWidget {
  const BottomNavBarView({
    required this.activeIndex,
    required this.reduceMotion,
    required this.badgeFor,
    required this.onTap,
    super.key,
  });

  final int activeIndex;
  final bool reduceMotion;
  final int Function(String id) badgeFor;
  final void Function(int index) onTap;

  @override
  State<BottomNavBarView> createState() => _BottomNavBarViewState();
}

class _BottomNavBarViewState extends State<BottomNavBarView>
    with TickerProviderStateMixin {
  bool _dragging = false;
  double _dragLeft = 0;
  int _dragHoverIndex = -1;
  bool _textVisible = true;
  Timer? _fadeTimer;

  late final AnimationController _liftCtrl;
  late final Animation<double> _liftScale;

  AnimationController? _pillCtrl;
  Animation<double>? _pillBounce;

  @override
  void initState() {
    super.initState();
    _liftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _liftScale = Tween<double>(begin: 1.0, end: 1.4)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_liftCtrl);

    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pillBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.03).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 0.99).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.99, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
    ]).animate(_pillCtrl!);

    // Start fade timer on first load.
    Future.microtask(_showText);
  }

  @override
  void didUpdateWidget(BottomNavBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _showText();
      _pillCtrl?.forward(from: 0);
    }
  }

  void _showText() {
    _fadeTimer?.cancel();
    setState(() => _textVisible = true);
    _fadeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _textVisible = false);
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _pillCtrl?.dispose();
    _liftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.activeIndex;
    final reduceMotion = widget.reduceMotion;
    final bottomInset = math.max(MediaQuery.viewPaddingOf(context).bottom, 8.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pill is centred at 80% of the screen width; pill and rail are
          // aspect-locked to their PNGs (height derived from width, no squash).
          final barWidth = constraints.maxWidth * _kWidthFrac;
          final capsuleHeight = barWidth * _kCapsuleAspect;

          // Perfect 5×2 grid: every cell is a square (height = width).
          // Both rows share the same column widths — alignment by construction.
          final railMargin = barWidth * railMarginFrac;
          final contentWidth = barWidth - 2 * railMargin;
          final cellSize = contentWidth / navTabs.length; // square cell side
          final railWidth = cellSize;
          final railHeight = railWidth * _kRailAspect;
          final visibleAbove = railHeight - _kRailOverlap;
          final row1H = cellSize * 0.2; // row 1 height — 80% shorter than a full cell
          final textRowH = (cellSize * 0.45).clamp(20.0, 32.0); // scales with screen
          final totalHeight = row1H + capsuleHeight;


          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: barWidth,
                height: totalHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Single label — slides to centre on the active column,
                    // full barWidth wide so it never clips at any font scale.
                    // Fades out 5 s after last tab change.
                    AnimatedPositioned(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 380),
                      curve: Curves.easeInOutCubic,
                      top: -textRowH,
                      left: railMargin + cellSize * activeIndex + cellSize / 2 - barWidth / 2,
                      width: barWidth,
                      height: textRowH,
                      child: AnimatedOpacity(
                        opacity: _textVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        child: Center(
                          child: Text(
                            const {
                              'messages': 'Chat',
                              'connections': 'Connections',
                              'discover': 'Discovery',
                              'tandy': 'Tandy',
                              'profile': 'Profile',
                            }[navTabs[activeIndex].id] ?? navTabs[activeIndex].label,
                            style: TextStyle(
                              color: const Color(0xFFFF8C42).withValues(alpha: 0.75),
                              fontSize: (cellSize * 0.22).clamp(9.0, 16.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    // DEBUG row 1 — set opacity to 0.35 to show, 0 to hide.
                    Positioned(
                      top: 0,
                      left: railMargin,
                      right: railMargin,
                      height: row1H,
                      child: Opacity(
                        opacity: 0,
                        child: Row(
                          children: [
                            for (var i = 0; i < navTabs.length; i++)
                              Expanded(
                                child: Container(
                                  color: const [
                                    Color(0xFFFF0000),
                                    Color(0xFF00AA00),
                                    Color(0xFF0000FF),
                                    Color(0xFFFF8800),
                                    Color(0xFF9900CC),
                                  ][i].withValues(alpha: 0.35),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // 1. Rail dome — draggable. While dragging: follows finger.
                    //    On release: snaps to nearest column via onTap.
                    if (_dragging)
                      Positioned(
                        top: (row1H - railHeight) / 2,
                        left: _dragLeft,
                        width: cellSize,
                        height: railHeight,
                        child: ScaleTransition(
                          scale: _liftScale,
                          child: NavRailIndicator(
                            activeIndex: activeIndex,
                            width: railWidth,
                            height: railHeight,
                            reduceMotion: true,
                            color: _kSurfaceColor,
                          ),
                        ),
                      )
                    else
                      AnimatedPositioned(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 380),
                        curve: Curves.easeInOutCubic,
                        top: (row1H - railHeight) / 2,
                        left: railMargin + cellSize * activeIndex,
                        width: cellSize,
                        height: railHeight,
                        child: NavRailIndicator(
                          activeIndex: activeIndex,
                          width: railWidth,
                          height: railHeight,
                          reduceMotion: reduceMotion,
                          color: _kSurfaceColor,
                        ),
                      ),
                    // 2. White capsule — below row 1.
                    Positioned(
                      top: row1H,
                      left: 0,
                      right: 0,
                      height: capsuleHeight,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([if (_pillCtrl != null) _pillCtrl!, _liftCtrl]),
                        builder: (context, child) {
                          final scaleY = _dragging
                              ? 1.0 - (_liftScale.value - 1.0) * 0.15
                              : (_pillBounce?.value ?? 1.0);
                          return Transform.scale(
                            scaleY: scaleY,
                            alignment: Alignment.bottomCenter,
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/icons/nav/nav_capsule.png',
                          fit: BoxFit.fill,
                          color: _kSurfaceColor,
                          colorBlendMode: BlendMode.srcIn,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    // 3. Icon grid row — below row 1.
                    Positioned(
                      top: row1H,
                      left: railMargin,
                      right: railMargin,
                      height: capsuleHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < navTabs.length; i++)
                            Expanded(
                              child: Stack(
                                children: [
                                  _NavCell(
                                    descriptor: navTabs[i],
                                    isActive: i == activeIndex,
                                    badge: widget.badgeFor(navTabs[i].id),
                                    activeLift: visibleAbove * 0.5,
                                    cellSize: cellSize,
                                    onTap: () => widget.onTap(i),
                                  ),
                                  // DEBUG border — set visible: true to show grid.
                                  Visibility(
                                    visible: false,
                                    child: IgnorePointer(
                                      child: Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: const [
                                                Color(0xFFFF0000),
                                                Color(0xFF00AA00),
                                                Color(0xFF0000FF),
                                                Color(0xFFFF8800),
                                                Color(0xFF9900CC),
                                              ][i].withValues(alpha: 0.7),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // ── Drag handle (highest z-index, full row-1 strip) ──────
                    // Invisible. Covers every column so the dome is easy to
                    // grab from anywhere along row 1. Pan start teleports the
                    // dome to the finger's column, then dragging moves it live.
                    Positioned(
                      top: (row1H - math.max(48.0, row1H)) / 2,
                      left: 0,
                      right: 0,
                      height: math.max(48.0, row1H),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) {
                          // Snap dome to whichever column the finger starts on.
                          final startLeft = (d.localPosition.dx - railMargin - cellSize / 2)
                              .clamp(railMargin, railMargin + cellSize * (navTabs.length - 1));
                          final startIndex = ((d.localPosition.dx - railMargin) / cellSize)
                              .floor()
                              .clamp(0, navTabs.length - 1);
                          setState(() {
                            _dragging = true;
                            _dragLeft = startLeft;
                            _dragHoverIndex = startIndex;
                          });
                          _liftCtrl.forward(from: 0);
                          _hapticLift();
                        },
                        onPanUpdate: (d) {
                          final newLeft = (_dragLeft + d.delta.dx).clamp(
                            railMargin,
                            railMargin + cellSize * (navTabs.length - 1),
                          );
                          final hoverIndex = ((newLeft - railMargin) / cellSize)
                              .round()
                              .clamp(0, navTabs.length - 1);
                          if (hoverIndex != _dragHoverIndex) {
                            _dragHoverIndex = hoverIndex;
                            _hapticTick();
                          }
                          setState(() { _dragLeft = newLeft; });
                        },
                        onPanEnd: (_) {
                          final snapped = ((_dragLeft - railMargin) / cellSize)
                              .round()
                              .clamp(0, navTabs.length - 1);
                          setState(() => _dragging = false);
                          _liftCtrl.reverse();
                          _pillCtrl?.forward(from: 0);
                          _hapticSelect();
                          widget.onTap(snapped);
                          _showText();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Single column ───────────────────────────────────────────────────────────

/// One column: an idle line-icon that swaps to its colourful clicked icon when
/// selected, with a glow halo, a pop scale on select, and a lift into the dome.
class _NavCell extends StatefulWidget {
  const _NavCell({
    required this.descriptor,
    required this.isActive,
    required this.badge,
    required this.activeLift,
    required this.cellSize,
    required this.onTap,
  });

  final NavTabDescriptor descriptor;
  final bool isActive;
  final int badge;
  final double activeLift;
  final double cellSize;
  final VoidCallback onTap;

  @override
  State<_NavCell> createState() => _NavCellState();
}

class _NavCellState extends State<_NavCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double> _scale;
  Animation<double>? _glowAnim;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Spring bounce: shoot up → overshoot down → settle above → settle.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.55)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.55, end: 0.82)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 17,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 17,
      ),
    ]).animate(_pop);

    // Glow pulses out fast then fades — peaks at 30% of the animation.
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pop,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(_NavCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pop when this tab becomes the selected one.
    if (!oldWidget.isActive && widget.isActive) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final iconAsset = isActive
        ? _kClickedIcons[widget.descriptor.id]!
        : _kIdleIcons[widget.descriptor.id]!;
    final iconHeight = isActive
        ? widget.cellSize * 0.85
        : widget.cellSize * 0.60;
    final glow = _kGlowColors[widget.descriptor.id] ?? Colors.white;

    return Semantics(
      // Visible labels removed; keep the semantic label for screen readers.
      key: ValueKey('nav-cell-${widget.descriptor.id}'),
      label: widget.badge > 0
          ? '${widget.descriptor.label}, ${widget.badge} unread'
          : widget.descriptor.label,
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: () {
          _hapticSelect();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          // Active icon lifts up into the dome's centre.
          child: Transform.translate(
            offset: Offset(0, isActive ? -widget.activeLift : 0),
            child: ScaleTransition(
              scale: _scale,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Glow halo — pulses out on select then settles.
                  if (isActive)
                    AnimatedBuilder(
                      animation: _pop,
                      builder: (context, _) {
                        final t = (_glowAnim?.value ?? 0.0);
                        return Container(
                          width: iconHeight,
                          height: iconHeight,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: glow.withValues(alpha: 0.4 + 0.35 * t),
                                blurRadius: 18 + 26 * t,
                                spreadRadius: 1 + 12 * t,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  Image.asset(
                    iconAsset,
                    height: iconHeight,
                    fit: BoxFit.contain,
                    color: isActive ? _kIconActiveColor : null,
                    colorBlendMode: isActive ? BlendMode.modulate : null,
                    excludeFromSemantics: true,
                  ),
                  if (widget.badge > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: NavUnreadBadge(count: widget.badge),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

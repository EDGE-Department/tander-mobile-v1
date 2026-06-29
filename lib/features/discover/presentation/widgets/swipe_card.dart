/// Tinder-style swipe card — pixel-perfect port of tander-web swipe-card.tsx.
///
/// Uses [GestureDetector] + [AnimationController] with spring physics
/// for full control over drag, fling, and snap-back behaviour.
/// Overlay widgets (stamps, profile info, photo indicators) live in
/// `swipe_card_overlay.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/swipe_card_overlay.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_avatar.dart';

// ── Constants (from web swipe-card.tsx) ─────────────────────────────────

const double _swipeThresholdPx = 100;
const double _velocityThresholdPxPerSec = 600;
const double _stampAppearStart = 25;
const double _stampAppearEnd = 120;
const double _dragElastic = 0.18;

const double _snapBackStiffness = 500;
const double _snapBackDamping = 32;

const int _flingDurationMs = 380;
const int _wiggleDurationMs = 850;
const int _wiggleDelayMs = 900;
const double _wiggleAmplitude = 22;

// ── Widget ──────────────────────────────────────────────────────────────

class SwipeCard extends StatefulWidget {
  const SwipeCard({
    required this.candidate,
    required this.onLikeComplete,
    required this.onPassComplete,
    required this.onViewProfile,
    required this.onDragProgress,
    this.isDisabled = false,
    super.key,
  });

  final DiscoveryCandidate candidate;
  final VoidCallback onLikeComplete;
  final VoidCallback onPassComplete;
  final VoidCallback onViewProfile;
  final ValueChanged<double> onDragProgress;
  final bool isDisabled;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  double _dragX = 0;
  double _dragY = 0;
  bool _isDragging = false;
  bool _isFlung = false;
  int _photoIndex = 0;

  late AnimationController _snapController;
  late AnimationController _wiggleController;

  List<String> get _allPhotos {
    final mainPhoto = widget.candidate.profilePhotoUrl;
    return [
      if (mainPhoto != null && mainPhoto.isNotEmpty) mainPhoto,
      ...widget.candidate.additionalPhotos,
    ];
  }


  double get _likeStampOpacity =>
      ((_dragX - _stampAppearStart) / (_stampAppearEnd - _stampAppearStart))
          .clamp(0.0, 1.0);

  double get _nopeStampOpacity =>
      ((-_dragX - _stampAppearStart) / (_stampAppearEnd - _stampAppearStart))
          .clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _initSnapController();
    _initWiggleController();
    _scheduleHintWiggle();
  }

  void _initSnapController() {
    _snapController = AnimationController.unbounded(vsync: this)
      ..addListener(_onSnapTick);
  }




  void _initWiggleController() {
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _wiggleDurationMs),
    )..addListener(_onWiggleTick);
  }

  @override
  void dispose() {
    _snapController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  // ── Hint wiggle (web: x [0,22,-22,0] 850ms delay 900ms) ─────────────

  void _scheduleHintWiggle() {
    Future.delayed(const Duration(milliseconds: _wiggleDelayMs), () {
      if (mounted && !_isDragging && !_isFlung) {
        _wiggleController.forward(from: 0);
      }
    });
  }

  void _onWiggleTick() {
    if (_isDragging || _isFlung) return;
    final double progress = _wiggleController.value;
    double wiggleX;
    if (progress < 0.25) {
      wiggleX = _wiggleAmplitude * (progress / 0.25);
    } else if (progress < 0.75) {
      wiggleX =
          _wiggleAmplitude - (2 * _wiggleAmplitude) * ((progress - 0.25) / 0.5);
    } else {
      wiggleX =
          -_wiggleAmplitude + _wiggleAmplitude * ((progress - 0.75) / 0.25);
    }
    setState(() => _dragX = wiggleX);
  }

  // ── Snap-back (web: stiffness 500, damping 32) ───────────────────────

  void _onSnapTick() {
    setState(() {
      _dragX = _snapController.value;
      _dragY = _dragY * 0.95;
    });
    widget.onDragProgress((_dragX / 150).clamp(-1.0, 1.0));
  }

  void _snapBack() {
    const spring = SpringDescription(
      mass: 1,
      stiffness: _snapBackStiffness,
      damping: _snapBackDamping,
    );
    _snapController.animateWith(SpringSimulation(spring, _dragX, 0, 0));
  }

  // ── Fling off screen (web: exit width+300, ease [0.32,0,0.67,0] 380ms)

  void _flingOffScreen({required bool isLike}) {
    _isFlung = true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetX = isLike ? screenWidth + 300 : -(screenWidth + 300);

    _snapController
        .animateTo(
          targetX,
          duration: const Duration(milliseconds: _flingDurationMs),
          curve: const Cubic(0.32, 0, 0.67, 0),
        )
        .then((_) {
          if (!mounted) return;
          if (isLike) {
            widget.onLikeComplete();
          } else {
            widget.onPassComplete();
          }
        });
  }

  // ── Gesture handlers ─────────────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (widget.isDisabled || _isFlung) return;
    _isDragging = true;
    _snapController.stop();
    _wiggleController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isFlung) return;
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy * _dragElastic;
    });
    widget.onDragProgress((_dragX / 150).clamp(-1.0, 1.0));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _isFlung) return;
    _isDragging = false;
    final velocityX = details.velocity.pixelsPerSecond.dx;

    if (_dragX > _swipeThresholdPx || velocityX > _velocityThresholdPxPerSec) {
      widget.onDragProgress(1);
      _flingOffScreen(isLike: true);
    } else if (_dragX < -_swipeThresholdPx ||
        velocityX < -_velocityThresholdPxPerSec) {
      widget.onDragProgress(-1);
      _flingOffScreen(isLike: false);
    } else {
      widget.onDragProgress(0);
      _snapBack();
      _dragY = 0;
    }
  }

  void _onCardTap(TapUpDetails details) {
    if (_allPhotos.length <= 1) return;
    final tapX = details.localPosition.dx;
    final cardWidth = context.size?.width ?? 300;
    setState(() {
      if (tapX > cardWidth / 2) {
        _photoIndex = (_photoIndex + 1).clamp(0, _allPhotos.length - 1);
      } else {
        _photoIndex = (_photoIndex - 1).clamp(0, _allPhotos.length - 1);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Impeller (Vulkan) on Adreno 6xx cannot composite this large card subtree
    // through an offscreen layer: any rotation/scale Transform, Opacity,
    // RepaintBoundary or image filter renders the card completely blank. A pure
    // *translation* Transform paints the child directly at an offset with NO
    // offscreen layer, so it renders correctly. The swipe is therefore driven
    // by translation only — the rotation tilt and entry scale are dropped on
    // this path because they require an offscreen layer Impeller fails to
    // rasterise. Drag, fling, snap-back, and the LIKE/NOPE stamps all work
    // (they key off _dragX, not a compositing transform).
    return Transform.translate(
      offset: Offset(_dragX, _dragY),
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapUp: _onCardTap,
        child: _cardBody(),
      ),
    );
  }

  Widget _cardBody() {
    // Shadow on an outer DecoratedBox; rounded corners via an explicit
    // ClipRRect. The previous Container(clipBehavior + decoration) emits a
    // ClipPath (BoxDecoration.getClipPath), which Impeller (Vulkan) on Adreno
    // 6xx fails to rasterise — leaving the whole card blank. ClipRRect uses the
    // optimised rounded-rect clip (the same one Material uses for the profile
    // modal, which renders correctly on this device).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhoto(),
            SwipePhotoIndicators(
              photoCount: _allPhotos.length,
              activeIndex: _photoIndex,
            ),
            SwipeLikeStamp(opacity: _likeStampOpacity),
            SwipeNopeStamp(opacity: _nopeStampOpacity),
            const SwipeBottomGradient(),
            SwipeProfileOverlay(
              candidate: widget.candidate,
              onViewProfile: widget.onViewProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (_allPhotos.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [Color(0xFFFEF0E0), Color(0xFFE0F5F4)],
          ),
        ),
        alignment: Alignment.center,
        child: TanderAvatar(
          displayName: widget.candidate.firstName,
          size: TanderAvatarSize.xxl,
        ),
      );
    }

    return Image.network(
      _allPhotos[_photoIndex],
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.subtle,
        alignment: Alignment.center,
        child: TanderAvatar(
          displayName: widget.candidate.firstName,
          size: TanderAvatarSize.xxl,
        ),
      ),
    );
  }
}

/// Tinder-style swipe card -- the signature discover interaction.
///
/// Uses [GestureDetector] + [AnimationController] with spring physics
/// for full control over the drag, fling, and snap-back behaviour.
/// Overlay widgets (stamps, profile info, photo indicators) are in
/// `swipe_card_overlay.dart`.
library;

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/swipe_card_overlay.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_avatar.dart';

// ── Constants ─────────────────────────────────────────────────────────

const double _swipeThresholdPx = 100;
const double _velocityThresholdPxPerSec = 600;
const double _maxRotationDeg = 18;
const double _dragRange = 250;
const double _stampAppearStart = 25;
const double _stampAppearEnd = 120;

const double _snapBackStiffness = 500;
const double _snapBackDamping = 32;
const double _entryStiffness = 380;
const double _entryDamping = 28;

// ── Widget ───────────────────────────────────────────────────────────

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
  late AnimationController _entryController;
  late AnimationController _wiggleController;
  late Animation<double> _entryScale;

  List<String> get _allPhotos {
    final mainPhoto = widget.candidate.profilePhotoUrl;
    return [
      if (mainPhoto != null && mainPhoto.isNotEmpty) mainPhoto,
      ...widget.candidate.additionalPhotos,
    ];
  }

  double get _rotationDeg =>
      (_dragX / _dragRange).clamp(-1.0, 1.0) * _maxRotationDeg;

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
    _initEntryController();
    _initWiggleController();
    _scheduleHintWiggle();
  }

  void _initSnapController() {
    _snapController = AnimationController.unbounded(vsync: this)
      ..addListener(_onSnapTick);
  }

  void _initEntryController() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: _SpringCurve(stiffness: _entryStiffness, damping: _entryDamping),
      ),
    );
    _entryController.forward();
  }

  void _initWiggleController() {
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..addListener(_onWiggleTick);
  }

  @override
  void dispose() {
    _snapController.dispose();
    _entryController.dispose();
    _wiggleController.dispose();
    super.dispose();
  }

  // ── Hint wiggle ───────────────────────────────────────────────────

  void _scheduleHintWiggle() {
    Future.delayed(const Duration(milliseconds: 900), () {
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
      wiggleX = 22 * (progress / 0.25);
    } else if (progress < 0.75) {
      wiggleX = 22 - 44 * ((progress - 0.25) / 0.5);
    } else {
      wiggleX = -22 + 22 * ((progress - 0.75) / 0.25);
    }
    setState(() => _dragX = wiggleX);
  }

  // ── Snap-back ─────────────────────────────────────────────────────

  void _onSnapTick() {
    setState(() {
      _dragX = _snapController.value;
      _dragY = _dragY * 0.95;
    });
    widget.onDragProgress((_dragX / 150).clamp(-1.0, 1.0));
  }

  void _snapBack() {
    final spring = SpringDescription(
      mass: 1,
      stiffness: _snapBackStiffness,
      damping: _snapBackDamping,
    );
    _snapController.animateWith(SpringSimulation(spring, _dragX, 0, 0));
  }

  // ── Fling off screen ──────────────────────────────────────────────

  void _flingOffScreen({required bool isLike}) {
    _isFlung = true;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetX = isLike ? screenWidth + 300 : -(screenWidth + 300);

    _snapController
        .animateTo(targetX,
            duration: const Duration(milliseconds: 380),
            curve: const Cubic(0.32, 0, 0.67, 0))
        .then((_) {
      if (!mounted) return;
      if (isLike) {
        widget.onLikeComplete();
      } else {
        widget.onPassComplete();
      }
    });
  }

  // ── Gesture handlers ──────────────────────────────────────────────

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
      _dragY += details.delta.dy * 0.18;
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

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rotationRad = _rotationDeg * math.pi / 180;

    return AnimatedBuilder(
      animation: _entryScale,
      builder: (context, child) => Transform.scale(
        scale: _entryScale.value,
        child: Opacity(
          opacity: _entryScale.value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_dragX, _dragY)
          ..rotateZ(rotationRad),
        alignment: Alignment.center,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onTapUp: _onCardTap,
          child: _cardBody(),
        ),
      ),
    );
  }

  Widget _cardBody() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: const [
          BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
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

    return CachedNetworkImage(
      imageUrl: _allPhotos[_photoIndex],
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.subtle),
      errorWidget: (_, _, _) => Container(
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

/// Custom curve that approximates a spring easing.
class _SpringCurve extends Curve {
  const _SpringCurve({required this.stiffness, required this.damping});
  final double stiffness;
  final double damping;

  @override
  double transformInternal(double progress) {
    final omega = math.sqrt(stiffness);
    final decay = math.exp(-damping * progress / (2 * omega));
    return 1 - decay * (1 - progress);
  }
}

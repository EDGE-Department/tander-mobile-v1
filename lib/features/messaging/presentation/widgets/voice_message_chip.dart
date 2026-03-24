import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

const Color _teal = AppColors.secondary;

/// Inline voice message player with animated waveform bars and progress.
/// Matches web VoiceChip component pixel-for-pixel.
class VoiceMessageChip extends StatefulWidget {
  const VoiceMessageChip({
    super.key,
    required this.isMine,
    this.durationSeconds,
    this.audioUrl,
  });

  final bool isMine;
  final int? durationSeconds;
  final String? audioUrl;

  @override
  State<VoiceMessageChip> createState() => _VoiceMessageChipState();
}

class _VoiceMessageChipState extends State<VoiceMessageChip>
    with TickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _progress = 0;
  int _elapsedSeconds = 0;
  bool _playerReady = false;

  // Waveform bounce animation
  late final AnimationController _waveController;
  // Play button scale animation
  late final AnimationController _buttonScaleController;
  late final Animation<double> _buttonScale;

  static const List<int> _barHeights = [4, 9, 14, 7, 11, 5, 9, 13, 6, 10, 8, 4, 7];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeOut),
    );

    _setupListeners();
  }

  void _setupListeners() {
    _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) return;
      final isPlaying = playerState.playing &&
          playerState.processingState != ProcessingState.completed;

      if (isPlaying && !_isPlaying) {
        _waveController.repeat(reverse: true);
      } else if (!isPlaying && _isPlaying) {
        _waveController.stop();
        _waveController.value = 0;
      }

      setState(() => _isPlaying = isPlaying);

      if (playerState.processingState == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
        if (mounted) setState(() { _progress = 0; _elapsedSeconds = 0; });
      }
    });

    _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      final totalDuration = _audioPlayer.duration;
      final durationMs = totalDuration?.inMilliseconds ??
          ((widget.durationSeconds ?? 0) * 1000);
      setState(() {
        _elapsedSeconds = position.inSeconds;
        _progress = durationMs > 0 ? position.inMilliseconds / durationMs : 0;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _waveController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.audioUrl == null) return;

    // Button press feedback
    await _buttonScaleController.forward();
    _buttonScaleController.reverse();

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (!_playerReady) {
          await _audioPlayer.setUrl(widget.audioUrl!);
          _playerReady = true;
        }
        await _audioPlayer.play();
      }
    } on Object catch (error) {
      AppLogger.error('Voice playback failed', operation: 'VoiceMessageChip', error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.durationSeconds ?? 0;
    final displaySeconds = _isPlaying ? _elapsedSeconds : totalSeconds;
    final timeLabel = _formatDuration(displaySeconds);

    final playColor = widget.isMine ? Colors.white : _teal;
    final trackColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.24)
        : _teal.withValues(alpha: 0.22);
    final fillColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.96)
        : _teal;
    final timeColor = widget.isMine
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF7C7060);
    final playBg = widget.isMine
        ? Colors.white.withValues(alpha: 0.18)
        : _teal.withValues(alpha: 0.11);
    final playRing = widget.isMine
        ? Colors.white.withValues(alpha: 0.34)
        : _teal.withValues(alpha: 0.32);

    return SizedBox(
      width: 208,
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button with scale feedback
              ScaleTransition(
                scale: _buttonScale,
                child: GestureDetector(
                  onTap: widget.audioUrl != null ? _togglePlay : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: playBg,
                      border: Border.all(color: playRing, width: 1.5),
                    ),
                    child: Center(
                      child: _isPlaying
                          ? _PauseBars(color: playColor)
                          : _PlayTriangle(color: playColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Animated waveform
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return ClipRect(
                        child: Stack(
                          children: [
                            // Track bars (background)
                            _WaveformRow(
                              barHeights: _barHeights,
                              color: trackColor,
                              waveValue: 0,
                              isAnimating: false,
                            ),
                            // Fill bars (foreground, clipped by progress)
                            ClipRect(
                              clipper: _ProgressClipper(_progress),
                              child: _WaveformRow(
                                barHeights: _barHeights,
                                color: fillColor,
                                waveValue: _waveController.value,
                                isAnimating: _isPlaying,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Duration/elapsed
              SizedBox(
                width: 34,
                child: Text(
                  timeLabel,
                  textAlign: TextAlign.right,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress track
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: SizedBox(
              height: 2.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 120),
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper that reveals content from left based on progress (0..1).
class _ProgressClipper extends CustomClipper<Rect> {
  _ProgressClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_ProgressClipper oldClipper) => progress != oldClipper.progress;
}

/// Play triangle icon matching web's CSS border-triangle.
class _PlayTriangle extends StatelessWidget {
  const _PlayTriangle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: CustomPaint(
        size: const Size(12, 13),
        painter: _TrianglePainter(color),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => color != old.color;
}

/// Pause icon — two vertical bars matching web.
class _PauseBars extends StatelessWidget {
  const _PauseBars({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 3.5, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color)),
        const SizedBox(width: 3.5),
        Container(width: 3.5, height: 12, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color)),
      ],
    );
  }
}

/// Waveform row that can optionally animate bars when playing.
/// Web animation: bars pulse with staggered timing using t-wave-a/b/c.
class _WaveformRow extends StatelessWidget {
  const _WaveformRow({
    required this.barHeights,
    required this.color,
    required this.waveValue,
    required this.isAnimating,
  });

  final List<int> barHeights;
  final Color color;
  final double waveValue;
  final bool isAnimating;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barHeights.length, (index) {
        final baseHeight = barHeights[index].toDouble();
        double height = baseHeight;

        if (isAnimating) {
          // Staggered wave: each bar oscillates with a phase offset
          final phase = (index * 0.48) + waveValue * math.pi * 2;
          final wave = math.sin(phase);
          // Bars grow/shrink by up to 40% of their base height
          height = baseHeight + (baseHeight * 0.4 * wave);
          height = height.clamp(2.0, 20.0);
        }

        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            color: color,
          ),
        );
      }),
    );
  }
}

String _formatDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

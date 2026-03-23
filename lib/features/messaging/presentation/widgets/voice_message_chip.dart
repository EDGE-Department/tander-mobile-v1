import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _teal = AppColors.secondary;

/// Inline voice message player with waveform bars and progress indicator.
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

class _VoiceMessageChipState extends State<VoiceMessageChip> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((playerState) {
      if (!mounted) return;
      setState(() => _isPlaying = playerState == PlayerState.playing);
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      final durationMs = (widget.durationSeconds ?? 0) * 1000;
      setState(() {
        _elapsedSeconds = position.inSeconds;
        _progress = durationMs > 0 ? position.inMilliseconds / durationMs : 0;
      });
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _progress = 0;
        _elapsedSeconds = 0;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.audioUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl!));
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

    return SizedBox(
      width: 208,
      child: Column(
        children: [
          Row(
            children: [
              _PlayButton(
                onTap: _togglePlay,
                isPlaying: _isPlaying,
                playColor: playColor,
                backgroundColor: widget.isMine
                    ? Colors.white.withValues(alpha: 0.18)
                    : _teal.withValues(alpha: 0.11),
                borderColor: widget.isMine
                    ? Colors.white.withValues(alpha: 0.34)
                    : _teal.withValues(alpha: 0.32),
                isEnabled: widget.audioUrl != null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WaveformBars(
                  progress: _progress,
                  trackColor: trackColor,
                  fillColor: fillColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                timeLabel,
                style: AppTypography.caption.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: timeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 54),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                minHeight: 2.5,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.onTap,
    required this.isPlaying,
    required this.playColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.isEnabled,
  });

  final VoidCallback onTap;
  final bool isPlaying;
  final Color playColor;
  final Color backgroundColor;
  final Color borderColor;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          size: 18,
          color: playColor,
        ),
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  static const List<int> _barHeights = [4, 9, 14, 7, 11, 5, 9, 13, 6, 10, 8, 4, 7];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barHeights.length, (index) {
          final barFraction = (index + 1) / _barHeights.length;
          final isFilled = barFraction <= progress;

          return Container(
            width: 3,
            height: _barHeights[index].toDouble(),
            margin: const EdgeInsets.symmetric(horizontal: 1.25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: isFilled ? fillColor : trackColor,
            ),
          );
        }),
      ),
    );
  }
}

String _formatDuration(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

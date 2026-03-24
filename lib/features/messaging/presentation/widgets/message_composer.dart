import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/notifiers/message_thread_notifier.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/message_thread_state.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/composer_recording_row.dart';

const Color _orange = AppColors.primary;
const Color _teal = AppColors.secondary;

/// Message composer with text input, photo attachment, and voice recording.
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _recordingFilePath;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    setState(() {});
    ref
        .read(messageThreadNotifierProvider(widget.conversationId).notifier)
        .notifyTyping();
  }

  Future<void> _handleSend() async {
    final trimmedText = _textController.text.trim();
    if (trimmedText.isEmpty) return;

    _textController.clear();
    setState(() {});
    _focusNode.requestFocus();

    await ref
        .read(messageThreadNotifierProvider(widget.conversationId).notifier)
        .sendTextMessage(trimmedText);
  }

  void _showPhotoSourceMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PhotoSourceSheet(
        onGallery: () {
          Navigator.of(sheetContext).pop();
          _handlePickImage(ImageSource.gallery);
        },
        onCamera: () {
          Navigator.of(sheetContext).pop();
          _handlePickImage(ImageSource.camera);
        },
      ),
    );
  }

  Future<void> _handlePickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    await ref
        .read(messageThreadNotifierProvider(widget.conversationId).notifier)
        .sendImageMessage(filePath: pickedFile.path, fileName: pickedFile.name);
  }

  Future<void> _handleRecordStart() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      AppLogger.warning('Microphone permission denied', operation: 'MessageComposer');
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _recordingFilePath = filePath;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  Future<void> _handleRecordSend() async {
    _recordingTimer?.cancel();
    final durationAtStop = _recordingSeconds;
    final filePath = _recordingFilePath;
    final recordedPath = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
      _recordingFilePath = null;
    });

    final resolvedPath = recordedPath ?? filePath;
    if (resolvedPath == null) return;

    await ref
        .read(messageThreadNotifierProvider(widget.conversationId).notifier)
        .sendVoiceMessage(
          filePath: resolvedPath,
          fileName: 'voice_message.m4a',
          durationSeconds: durationAtStop > 0 ? durationAtStop : 1,
        );
  }

  Future<void> _handleRecordCancel() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
      _recordingFilePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final threadState = ref.watch(messageThreadNotifierProvider(widget.conversationId));
    final isSending = threadState is MessageThreadLoaded && threadState.isSending;
    final isSendingMedia = threadState is MessageThreadLoaded && threadState.isSendingMedia;
    final hasText = _textController.text.trim().isNotEmpty;
    final canSend = hasText && !isSending && !_isRecording;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0x00F8F1E6), Color(0xFAF9F3EA), Color(0xFFF9F3EA)],
        ),
        border: Border(top: BorderSide(color: Color(0x99DDD3C2))),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFAFFFDFA),
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: const Color(0xCCDDD3C2), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFF764F21).withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: _isRecording
            ? ComposerRecordingRow(recordingSeconds: _recordingSeconds, onCancel: _handleRecordCancel, onSend: _handleRecordSend)
            : _ComposerInputRow(
                textController: _textController, focusNode: _focusNode,
                onTextChanged: _onTextChanged, onSend: _handleSend,
                onPickImage: _showPhotoSourceMenu, onRecordStart: _handleRecordStart,
                canSend: canSend, isSending: isSending, isSendingMedia: isSendingMedia,
              ),
      ),
    );
  }
}

// ─── Input row ────────────────────────────────────────────────────────────

class _ComposerInputRow extends StatelessWidget {
  const _ComposerInputRow({
    required this.textController, required this.focusNode,
    required this.onTextChanged, required this.onSend,
    required this.onPickImage, required this.onRecordStart,
    required this.canSend, required this.isSending, required this.isSendingMedia,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onRecordStart;
  final bool canSend;
  final bool isSending;
  final bool isSendingMedia;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: isSendingMedia ? null : onPickImage,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _teal.withValues(alpha: 0.08)),
            child: Icon(Icons.image, size: 19, color: isSendingMedia ? _teal.withValues(alpha: 0.4) : _teal),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: textController, focusNode: focusNode,
              onChanged: onTextChanged, maxLines: null,
              textInputAction: TextInputAction.newline,
              style: AppTypography.body.copyWith(color: const Color(0xFF18110A), fontSize: 16, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _TrailingButton(canSend: canSend, isSending: isSending, isSendingMedia: isSendingMedia, onSend: onSend, onRecordStart: onRecordStart),
      ],
    );
  }
}

class _TrailingButton extends StatelessWidget {
  const _TrailingButton({
    required this.canSend, required this.isSending,
    required this.isSendingMedia, required this.onSend,
    required this.onRecordStart,
  });

  final bool canSend;
  final bool isSending;
  final bool isSendingMedia;
  final VoidCallback onSend;
  final VoidCallback onRecordStart;

  @override
  Widget build(BuildContext context) {
    if (canSend) {
      return ComposerActionButton(
        onTap: onSend,
        gradient: const LinearGradient(colors: [_orange, Color(0xFFD06A18)]),
        icon: isSending
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : const Icon(Icons.send, size: 18, color: Colors.white),
      );
    }

    if (isSendingMedia) {
      return Container(
        width: 44, height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _teal.withValues(alpha: 0.08)),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(_teal)))),
      );
    }

    return ComposerActionButton(
      onTap: onRecordStart,
      color: _teal.withValues(alpha: 0.08),
      icon: const Icon(Icons.mic, size: 18, color: _teal),
    );
  }
}

// ─── Photo source bottom sheet ──────────────────────────────────────────────

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet({
    required this.onGallery,
    required this.onCamera,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xCCDDD3C2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF764F21).withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD3C2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          _PhotoSourceOption(
            icon: Icons.photo_library_outlined,
            label: 'Photo Library',
            onTap: onGallery,
          ),
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: const Color(0xFFDDD3C2).withValues(alpha: 0.5),
          ),
          _PhotoSourceOption(
            icon: Icons.camera_alt_outlined,
            label: 'Take Photo',
            onTap: onCamera,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PhotoSourceOption extends StatelessWidget {
  const _PhotoSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _teal.withValues(alpha: 0.08),
                ),
                child: Icon(icon, size: 18, color: _teal),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1209),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

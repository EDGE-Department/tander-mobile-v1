import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

/// Immutable snapshot of the entire call UI state.
///
/// Mirrors the web's `CallState` interface — status, call info, local/remote
/// media state, duration, end reason, and error message.
final class CallState {
  const CallState({
    required this.status,
    this.callInfo,
    this.media = const MediaState(),
    this.remoteMedia = const RemoteMediaState(),
    this.durationSeconds = 0,
    this.endReason,
    this.errorMessage,
  });

  final CallStatus status;
  final CallInfo? callInfo;
  final MediaState media;
  final RemoteMediaState remoteMedia;
  final int durationSeconds;
  final CallEndReason? endReason;
  final String? errorMessage;

  /// Factory for the initial idle state.
  static const CallState initial = CallState(status: CallIdle());

  CallState copyWith({
    CallStatus? status,
    CallInfo? callInfo,
    MediaState? media,
    RemoteMediaState? remoteMedia,
    int? durationSeconds,
    CallEndReason? endReason,
    String? errorMessage,
    bool clearCallInfo = false,
    bool clearEndReason = false,
    bool clearErrorMessage = false,
  }) {
    return CallState(
      status: status ?? this.status,
      callInfo: clearCallInfo ? null : (callInfo ?? this.callInfo),
      media: media ?? this.media,
      remoteMedia: remoteMedia ?? this.remoteMedia,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      endReason: clearEndReason ? null : (endReason ?? this.endReason),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  /// Whether the call is in a pre-connect state (initiating, ringing, connecting).
  bool get isPreConnect =>
      status is CallInitiating ||
      status is CallRinging ||
      status is CallConnecting;

  /// Whether the call has ended (ended or failed).
  bool get isEnded => status is CallEnded || status is CallFailed;

  /// Whether the call is currently connected.
  bool get isConnected => status is CallConnected;

  /// Whether we're in an incoming ringing state.
  bool get isIncomingRinging =>
      status is CallRinging && callInfo?.direction == CallDirection.incoming;

  /// Formatted duration as MM:SS.
  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Native event emitted by [TwilioNativeBridge].
sealed class TwilioRoomEvent {
  const TwilioRoomEvent();
}

final class RoomConnected extends TwilioRoomEvent {
  const RoomConnected({
    required this.roomSid,
    required this.roomName,
    required this.localParticipantSid,
  });
  final String roomSid;
  final String roomName;
  final String localParticipantSid;
}

final class RoomConnectFailure extends TwilioRoomEvent {
  const RoomConnectFailure({required this.code, required this.message});
  final int code;
  final String message;
}

final class RoomReconnecting extends TwilioRoomEvent {
  const RoomReconnecting({required this.message});
  final String message;
}

final class RoomReconnected extends TwilioRoomEvent {
  const RoomReconnected();
}

final class RoomDisconnected extends TwilioRoomEvent {
  const RoomDisconnected({required this.code, required this.message});
  final int code;
  final String message;
}

final class ParticipantConnected extends TwilioRoomEvent {
  const ParticipantConnected({
    required this.participantSid,
    required this.identity,
  });
  final String participantSid;
  final String identity;
}

final class ParticipantDisconnected extends TwilioRoomEvent {
  const ParticipantDisconnected({
    required this.participantSid,
    required this.identity,
  });
  final String participantSid;
  final String identity;
}

final class AudioTrackSubscribed extends TwilioRoomEvent {
  const AudioTrackSubscribed({
    required this.participantSid,
    required this.trackSid,
  });
  final String participantSid;
  final String trackSid;
}

final class NetworkQualityChanged extends TwilioRoomEvent {
  const NetworkQualityChanged({
    required this.participantSid,
    required this.level,
  });
  final String participantSid;
  final String level;
}

final class RemoteVideoTrackSubscribed extends TwilioRoomEvent {
  const RemoteVideoTrackSubscribed({
    required this.participantSid,
    required this.trackSid,
  });
  final String participantSid;
  final String trackSid;
}

final class RemoteVideoTrackUnsubscribed extends TwilioRoomEvent {
  const RemoteVideoTrackUnsubscribed({required this.participantSid});
  final String participantSid;
}

/// Emitted once the local camera track is created (camera permission granted
/// and a front camera exists) — drives the self-view PIP.
final class LocalVideoTrackPublished extends TwilioRoomEvent {
  const LocalVideoTrackPublished();
}

/// Peer toggled their camera back on (track stays subscribed; frames resume).
final class RemoteVideoEnabled extends TwilioRoomEvent {
  const RemoteVideoEnabled({required this.participantSid});
  final String participantSid;
}

/// Peer turned their camera off (track still subscribed, no frames) — show
/// their avatar instead of a frozen frame.
final class RemoteVideoDisabled extends TwilioRoomEvent {
  const RemoteVideoDisabled({required this.participantSid});
  final String participantSid;
}

/// The native CallStyle notification's "Hang Up" button was tapped while the
/// user was outside the app. Drives the FULL hangup (backend end + Twilio
/// disconnect + UI clear) — handled by [V2CallkitListener], which holds the
/// datasource + active-call notifier. (The notifier itself only clears UI on
/// RoomDisconnected, so without this the backend call would leak open.)
final class HangUpRequested extends TwilioRoomEvent {
  const HangUpRequested();
}

/// Dart-side client of the Android `tander/twilio_call` MethodChannel.
///
/// On iOS the same channel name will be wired in Stage 1 — this bridge
/// is platform-agnostic. Audio-only ConnectOptions for Stage 2; Stage 3
/// adds video tracks + the PlatformView for renderer attachment.
///
/// Singleton pattern via [instance] — the underlying native singleton
/// owns the Twilio Room lifecycle across Flutter engine restarts, so the
/// Dart side has to match.
final class TwilioNativeBridge {
  TwilioNativeBridge._() {
    _channel.setMethodCallHandler(_onCallFromNative);
  }

  static final TwilioNativeBridge instance = TwilioNativeBridge._();

  static const _channel = MethodChannel('tander/twilio_call');

  final StreamController<TwilioRoomEvent> _events =
      StreamController<TwilioRoomEvent>.broadcast();

  /// Stream of Room/Participant events from native side. Subscribe via
  /// `bridge.events.listen(...)`.
  Stream<TwilioRoomEvent> get events => _events.stream;

  // ─────────────────────────────────────────────────────────────────────
  // Flutter → native
  // ─────────────────────────────────────────────────────────────────────

  /// Connect to a Twilio Programmable Video room.
  ///
  /// [twilioToken] is the access token from
  /// `POST /api/v2/calls` (start) or
  /// `POST /api/v2/calls/{id}/{accept,token}`. Audio-only for Stage 2.
  Future<void> connect({
    required String roomName,
    required String twilioToken,
    bool isAudioOnly = true,
    String peerName = 'Caller',
  }) async {
    AppLogger.debug(
      'connect room=$roomName audioOnly=$isAudioOnly',
      operation: 'TwilioNativeBridge.connect',
    );
    await _channel.invokeMethod<void>('connect', {
      'roomName': roomName,
      'twilioToken': twilioToken,
      'isAudioOnly': isAudioOnly,
      'peerName': peerName,
    });
  }

  /// Hang up — terminates the Twilio Room session. Native side stops
  /// the foreground service and restores AudioManager state on
  /// `onDisconnected`.
  Future<void> disconnect() async {
    AppLogger.debug('disconnect', operation: 'TwilioNativeBridge.disconnect');
    await _channel.invokeMethod<void>('disconnect');
  }

  /// Mute/unmute local microphone.
  Future<void> setMuted(bool muted) async {
    await _channel.invokeMethod<void>('toggleMute', {'muted': muted});
  }

  /// Toggle speakerphone (earpiece ↔ loudspeaker).
  Future<void> setSpeakerphoneOn(bool on) async {
    await _channel.invokeMethod<void>('setSpeakerphone', {'on': on});
  }

  /// Enable/disable the local camera mid-call (B4). Track stays published.
  Future<void> setVideoEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setVideoEnabled', {'enabled': enabled});
  }

  // ─────────────────────────────────────────────────────────────────────
  // Native → Flutter
  // ─────────────────────────────────────────────────────────────────────

  Future<dynamic> _onCallFromNative(MethodCall call) async {
    final Map<String, dynamic> args = (call.arguments is Map)
        ? Map<String, dynamic>.from(call.arguments as Map)
        : <String, dynamic>{};

    final TwilioRoomEvent? event = switch (call.method) {
      'roomConnected' => RoomConnected(
        roomSid: args['roomSid'] as String? ?? '',
        roomName: args['roomName'] as String? ?? '',
        localParticipantSid: args['localParticipantSid'] as String? ?? '',
      ),
      'roomConnectFailure' => RoomConnectFailure(
        code: (args['code'] as num?)?.toInt() ?? 0,
        message: args['message'] as String? ?? '',
      ),
      'roomReconnecting' => RoomReconnecting(
        message: args['message'] as String? ?? '',
      ),
      'roomReconnected' => const RoomReconnected(),
      'roomDisconnected' => RoomDisconnected(
        code: (args['code'] as num?)?.toInt() ?? 0,
        message: args['message'] as String? ?? '',
      ),
      'participantConnected' => ParticipantConnected(
        participantSid: args['participantSid'] as String? ?? '',
        identity: args['identity'] as String? ?? '',
      ),
      'participantDisconnected' => ParticipantDisconnected(
        participantSid: args['participantSid'] as String? ?? '',
        identity: args['identity'] as String? ?? '',
      ),
      'audioTrackSubscribed' => AudioTrackSubscribed(
        participantSid: args['participantSid'] as String? ?? '',
        trackSid: args['trackSid'] as String? ?? '',
      ),
      'networkQualityChanged' => NetworkQualityChanged(
        participantSid: args['participantSid'] as String? ?? '',
        level: args['level'] as String? ?? '',
      ),
      'remoteVideoTrackSubscribed' => RemoteVideoTrackSubscribed(
        participantSid: args['participantSid'] as String? ?? '',
        trackSid: args['trackSid'] as String? ?? '',
      ),
      'remoteVideoTrackUnsubscribed' => RemoteVideoTrackUnsubscribed(
        participantSid: args['participantSid'] as String? ?? '',
      ),
      'localVideoTrackPublished' => const LocalVideoTrackPublished(),
      'remoteVideoEnabled' => RemoteVideoEnabled(
        participantSid: args['participantSid'] as String? ?? '',
      ),
      'remoteVideoDisabled' => RemoteVideoDisabled(
        participantSid: args['participantSid'] as String? ?? '',
      ),
      'hangUpRequested' => const HangUpRequested(),
      _ => null,
    };

    if (event != null) {
      _events.add(event);
    } else {
      AppLogger.warning(
        'unknown native call: ${call.method}',
        operation: 'TwilioNativeBridge._onCallFromNative',
      );
    }
    return null;
  }
}

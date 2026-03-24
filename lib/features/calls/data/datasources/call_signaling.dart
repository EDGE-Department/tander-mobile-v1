import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_constants.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

// ---------------------------------------------------------------------------
// Signal event — discriminated union for all incoming call/WebRTC events
// ---------------------------------------------------------------------------

sealed class CallSignalEvent {
  const CallSignalEvent();
}

final class IncomingCallEvent extends CallSignalEvent {
  const IncomingCallEvent({required this.payload});
  final StompIncomingCallPayload payload;
}

final class OfferEvent extends CallSignalEvent {
  const OfferEvent({required this.roomName, required this.sdp});
  final String roomName;
  final String sdp;
}

final class AnswerEvent extends CallSignalEvent {
  const AnswerEvent({required this.roomName, required this.sdp});
  final String roomName;
  final String sdp;
}

final class IceCandidateEvent extends CallSignalEvent {
  const IceCandidateEvent({required this.roomName, required this.candidate});
  final String roomName;
  final IceCandidateInfo candidate;
}

final class HangupEvent extends CallSignalEvent {
  const HangupEvent({required this.roomName, required this.reason});
  final String roomName;
  final String reason;
}

final class BusyEvent extends CallSignalEvent {
  const BusyEvent({required this.roomName});
  final String roomName;
}

final class MediaStateEvent extends CallSignalEvent {
  const MediaStateEvent({
    required this.roomName,
    this.audioMuted,
    this.videoOff,
  });
  final String roomName;
  final bool? audioMuted;
  final bool? videoOff;
}

final class CallAnsweredEvent extends CallSignalEvent {
  const CallAnsweredEvent({required this.roomName});
  final String roomName;
}

final class CallCancelledEvent extends CallSignalEvent {
  const CallCancelledEvent({required this.roomName});
  final String roomName;
}

final class CallAnsweredElsewhereEvent extends CallSignalEvent {
  const CallAnsweredElsewhereEvent({required this.roomName});
  final String roomName;
}

final class CallDeclinedElsewhereEvent extends CallSignalEvent {
  const CallDeclinedElsewhereEvent({required this.roomName});
  final String roomName;
}

final class CallDeclinedEvent extends CallSignalEvent {
  const CallDeclinedEvent({required this.roomName});
  final String roomName;
}

final class CallEndedEvent extends CallSignalEvent {
  const CallEndedEvent({required this.roomName});
  final String roomName;
}

// ---------------------------------------------------------------------------
// Signal handler typedef
// ---------------------------------------------------------------------------

typedef SignalHandler = void Function(CallSignalEvent event);

// ---------------------------------------------------------------------------
// Dedup — 2-second window matching web/Flutter originals
// ---------------------------------------------------------------------------

final class _DedupFilter {
  final Map<String, DateTime> _recentKeys = {};

  bool shouldProcess(String key) {
    final now = DateTime.now();

    // Purge stale entries older than 2 seconds
    _recentKeys.removeWhere(
      (_, timestamp) => now.difference(timestamp).inMilliseconds > 2000,
    );

    if (_recentKeys.containsKey(key)) return false;
    _recentKeys[key] = now;
    return true;
  }
}

// ---------------------------------------------------------------------------
// Subscribe to call lifecycle events (dual-subscribe: topic + queue)
// ---------------------------------------------------------------------------

/// Subscribes to incoming call events on both `/topic/calls.{userId}` and
/// `/user/{userId}/queue/calls` for reliability (backend sends to both).
///
/// Returns a teardown function that unsubscribes from both destinations.
StompUnsubscribeCallback subscribeToCallEvents(
  String userId,
  SignalHandler handler,
) {
  final dedup = _DedupFilter();

  void parseCallEvent(Map<String, Object?> body) {
    final payload = StompIncomingCallPayload.fromJson(body);
    final dedupKey = '${payload.type}_${payload.roomName}';

    if (!dedup.shouldProcess(dedupKey)) return;

    switch (payload.type) {
      case 'incoming_call':
        handler(IncomingCallEvent(payload: payload));
      case 'call_answered':
        handler(CallAnsweredEvent(roomName: payload.roomName));
      case 'call_cancelled':
        handler(CallCancelledEvent(roomName: payload.roomName));
      case 'call_answered_elsewhere':
        handler(CallAnsweredElsewhereEvent(roomName: payload.roomName));
      case 'call_declined_elsewhere':
        handler(CallDeclinedElsewhereEvent(roomName: payload.roomName));
      case 'call_declined':
        handler(CallDeclinedEvent(roomName: payload.roomName));
      case 'call_ended':
        handler(CallEndedEvent(roomName: payload.roomName));
    }
  }

  final unsubTopic = StompClientManager.instance.subscribe(
    CallDestinations.callEventsTopic(userId),
    parseCallEvent,
  );

  final unsubQueue = StompClientManager.instance.subscribe(
    CallDestinations.callEventsQueue(userId),
    parseCallEvent,
  );

  return () {
    unsubTopic();
    unsubQueue();
  };
}

// ---------------------------------------------------------------------------
// Subscribe to WebRTC room signals (triple-subscribe)
// ---------------------------------------------------------------------------

/// Subscribes to WebRTC signals for a specific call room.
///
/// Triple-subscribe: room topic + user queue + user topic (matches web).
/// Handles BOTH "ice" and "ice-candidate" signal types from the backend.
StompUnsubscribeCallback subscribeToRoomSignals(
  String roomId,
  String userId,
  SignalHandler handler,
) {
  final dedup = _DedupFilter();

  void parseWebrtcSignal(Map<String, Object?> body) {
    final signal = WebrtcSignalMessage.fromJson(body);
    // ICE candidates are unique — include candidate string in dedup key.
    // Other signals (offer, answer) are one-per-room so type+room suffices.
    final dedupKey = signal.type == 'ice' || signal.type == 'ice-candidate'
        ? '${signal.type}_${signal.roomName}_${signal.candidate?.candidate ?? body.hashCode}'
        : '${signal.type}_${signal.roomName}';

    if (!dedup.shouldProcess(dedupKey)) return;

    switch (signal.type) {
      case 'offer':
        if (signal.sdp != null) {
          handler(OfferEvent(roomName: signal.roomName, sdp: signal.sdp!));
        }
      case 'answer':
        if (signal.sdp != null) {
          handler(AnswerEvent(roomName: signal.roomName, sdp: signal.sdp!));
        }
      // Handle BOTH "ice" and "ice-candidate" — backend relays as "ice-candidate"
      case 'ice' || 'ice-candidate':
        if (signal.candidate != null) {
          handler(IceCandidateEvent(
            roomName: signal.roomName,
            candidate: signal.candidate!,
          ));
        }
      case 'hangup':
        handler(HangupEvent(
          roomName: signal.roomName,
          reason: signal.reason ?? 'hangup',
        ));
      case 'busy':
        handler(BusyEvent(roomName: signal.roomName));
      case 'media_state':
        handler(MediaStateEvent(
          roomName: signal.roomName,
          audioMuted: signal.audioMuted,
          videoOff: signal.videoOff,
        ));
    }
  }

  final roomDest = CallDestinations.roomTopic(roomId);
  final queueDest = CallDestinations.webrtcQueue(userId);
  final topicDest = CallDestinations.webrtcTopic(userId);

  AppLogger.info(
    'Subscribing to room signals',
    operation: 'CallSignaling',
    context: {'room': roomDest, 'queue': queueDest, 'topic': topicDest},
  );

  final unsubRoom = StompClientManager.instance.subscribe(
    roomDest,
    parseWebrtcSignal,
  );

  final unsubQueue = StompClientManager.instance.subscribe(
    queueDest,
    parseWebrtcSignal,
  );

  final unsubTopic = StompClientManager.instance.subscribe(
    topicDest,
    parseWebrtcSignal,
  );

  return () {
    unsubRoom();
    unsubQueue();
    unsubTopic();
  };
}

// ---------------------------------------------------------------------------
// Send signals — targetUserId as int in ALL payloads
// ---------------------------------------------------------------------------

void sendOffer(String roomName, String sdp, String targetUserId) {
  StompClientManager.instance.send(
    CallDestinations.sendOffer,
    <String, Object?>{
      'roomName': roomName,
      'sdp': sdp,
      'type': 'offer',
      'targetUserId': parseTargetUserId(targetUserId),
    },
  );
}

void sendAnswer(String roomName, String sdp, String targetUserId) {
  StompClientManager.instance.send(
    CallDestinations.sendAnswer,
    <String, Object?>{
      'roomName': roomName,
      'sdp': sdp,
      'type': 'answer',
      'targetUserId': parseTargetUserId(targetUserId),
    },
  );
}

void sendIceCandidate(
  String roomName,
  IceCandidateInfo candidate,
  String targetUserId,
) {
  StompClientManager.instance.send(
    CallDestinations.sendIce,
    <String, Object?>{
      'roomName': roomName,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
      'type': 'ice',
      'targetUserId': parseTargetUserId(targetUserId),
    },
  );
}

void sendHangup(String roomName, String reason, String targetUserId) {
  StompClientManager.instance.send(
    CallDestinations.sendHangup,
    <String, Object?>{
      'roomName': roomName,
      'reason': reason,
      'type': 'hangup',
      'targetUserId': parseTargetUserId(targetUserId),
    },
  );
}

void sendMediaStateSignal(
  String roomName,
  bool audioMuted,
  bool videoOff,
  String targetUserId,
) {
  StompClientManager.instance.send(
    CallDestinations.sendMediaState,
    <String, Object?>{
      'roomName': roomName,
      'type': 'media_state',
      'audioMuted': audioMuted,
      'videoOff': videoOff,
      'targetUserId': parseTargetUserId(targetUserId),
    },
  );
}

void sendRingAck(String roomName, String targetUserId) {
  StompClientManager.instance.send(
    CallDestinations.sendRingAck,
    <String, Object?>{
      'roomName': roomName,
      'type': 'ring_ack',
      'targetUserId': parseTargetUserId(targetUserId),
      'platform': 'flutter',
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
    },
  );
}

void sendBusy(String roomName, String targetUserId) {
  StompClientManager.instance.send(
    CallDestinations.sendHangup,
    <String, Object?>{
      'roomName': roomName,
      'reason': 'busy',
      'type': 'busy',
      'targetUserId': parseTargetUserId(targetUserId),
    },
  );
}

/// Calls domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Call Enums ────────────────────────────────────────────────

/// Whether the call is audio-only or includes video.
enum CallType {
  video,
  audio,
}

/// Whether the current user initiated or received the call.
enum CallDirection {
  outgoing,
  incoming,
}

/// Terminal status of a completed call.
enum CallStatus {
  completed,
  missed,
  declined,
  cancelled,
}

/// Lifecycle state of an in-progress call session.
enum CallSessionLifecycle {
  idle,
  incoming,
  outgoing,
  connecting,
  active,
  reconnecting,
  ended,
  failed,
}

// ── Call Participant ─────────────────────────────────────────

@immutable
class CallParticipant {
  const CallParticipant({
    required this.userId,
    required this.username,
    this.photoUrl,
  });

  final String userId;
  final String username;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallParticipant &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'CallParticipant(userId: $userId, username: $username)';
}

// ── Call Session State ───────────────────────────────────────

@immutable
class CallSessionState {
  const CallSessionState({
    required this.roomName,
    required this.callId,
    required this.callType,
    required this.lifecycle,
    required this.isLocalVideoEnabled,
    required this.isLocalAudioEnabled,
    this.remoteParticipant,
    this.startedAt,
    this.endedAt,
    this.failureReason,
  });

  final String roomName;
  final String callId;
  final CallType callType;
  final CallSessionLifecycle lifecycle;
  final CallParticipant? remoteParticipant;
  final bool isLocalVideoEnabled;
  final bool isLocalAudioEnabled;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? failureReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallSessionState &&
          runtimeType == other.runtimeType &&
          callId == other.callId &&
          lifecycle == other.lifecycle;

  @override
  int get hashCode => Object.hash(callId, lifecycle);

  @override
  String toString() => 'CallSessionState('
      'callId: $callId, '
      'lifecycle: ${lifecycle.name})';
}

// ── Call History Item ────────────────────────────────────────

@immutable
class CallHistoryItem {
  const CallHistoryItem({
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.participant,
    required this.direction,
    required this.status,
    required this.startedAt,
    this.durationSeconds,
    this.endedAt,
  });

  final String callId;
  final String roomName;
  final CallType callType;
  final CallParticipant participant;
  final CallDirection direction;
  final CallStatus status;
  final int? durationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallHistoryItem &&
          runtimeType == other.runtimeType &&
          callId == other.callId;

  @override
  int get hashCode => callId.hashCode;

  @override
  String toString() => 'CallHistoryItem('
      'callId: $callId, '
      'type: ${callType.name}, '
      'status: ${status.name})';
}

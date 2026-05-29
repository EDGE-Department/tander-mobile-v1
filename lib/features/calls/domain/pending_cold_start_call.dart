import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

/// SharedPreferences key for persisted call metadata.
///
/// Written by `CallPushBridge` during background/killed push handling.
/// Read by `V2CallkitListener` during app cold-start to reconstruct
/// the incoming call state before Riverpod initializes.
const String kPendingCallMetadataKey = 'pending_call_metadata';

/// Call metadata persisted by `CallPushBridge` for cold-start acceptance.
///
/// When the app is killed and an incoming call push arrives, the background
/// handler persists this metadata to SharedPreferences. On cold start,
/// `V2CallkitListener.consumeColdStartFromNative` reads it (via
/// `CallPushBridge.readPersistedMetadata`) to reconstruct the call info
/// needed to complete the connection.
final class PendingColdStartCall {
  const PendingColdStartCall({
    required this.roomId,
    required this.callType,
    required this.callerName,
    required this.callerUserId,
    this.callerPhoto,
    this.callerUsername = '',
    required this.timestamp,
    // ── Phase 5 v2 fields — null for legacy payloads ─────────────────
    this.callId,
    this.twilioRoomSid,
    this.acceptToken,
    this.declineToken,
    this.dismissToken,
    this.expiresAt,
  });

  final String roomId;
  final String callType;
  final String callerName;
  final String callerUserId;
  final String? callerPhoto;
  final String callerUsername;
  final DateTime timestamp;

  /// Real UUID `callId` from v2 push payload. Use this in preference to
  /// [roomId] when calling `/api/v2/calls/{callId}/...` endpoints. Null
  /// when the push came from the legacy `/api/twilio/video/*` path.
  final String? callId;

  /// Twilio Room SID from v2 payload — passed to `Video.connect` for
  /// reconnect after a network drop.
  final String? twilioRoomSid;

  /// Opaque single-use Base64URL tokens for killed-app action endpoints.
  /// `/api/v2/calls/{callId}/{accept,decline,dismiss}-action`. Never
  /// decode or inspect — wire format is intentional black box.
  final String? acceptToken;
  final String? declineToken;
  final String? dismissToken;

  /// ISO-8601 expiry from v2 payload. Tokens reject after this.
  final String? expiresAt;

  /// True when this metadata carries v2-payload fields. v2-aware UI uses
  /// the action-token path; legacy uses the JWT-authed path.
  bool get isV2 => acceptToken != null && callId != null;

  /// Reconstruct from SharedPreferences JSON map.
  factory PendingColdStartCall.fromMap(Map<String, dynamic> map) {
    return PendingColdStartCall(
      roomId: map['roomId'] as String? ?? '',
      callType: map['callType'] as String? ?? 'audio',
      callerName: map['callerName'] as String? ?? 'Unknown',
      callerUserId: (map['callerUserId'] ?? '').toString(),
      callerPhoto: map['callerPhoto'] as String?,
      callerUsername: (map['callerUsername'] ?? '').toString(),
      timestamp: map['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      callId: map['callId'] as String?,
      twilioRoomSid: map['twilioRoomSid'] as String?,
      acceptToken: map['acceptToken'] as String?,
      declineToken: map['declineToken'] as String?,
      dismissToken: map['dismissToken'] as String?,
      expiresAt: map['expiresAt'] as String?,
    );
  }

  /// Convert to [CallInfo] for the call engine.
  CallInfo toCallInfo() {
    return CallInfo(
      callId: roomId,
      roomName: roomId,
      callType: CallType.fromBackend(callType),
      direction: CallDirection.incoming,
      remoteUserId: callerUserId,
      remoteUsername: callerUsername.isNotEmpty ? callerUsername : callerName,
      remotePhotoUrl: callerPhoto,
    );
  }

  /// Whether this call metadata is stale (older than 2 minutes).
  bool get isStale => DateTime.now().difference(timestamp).inMinutes >= 2;
}

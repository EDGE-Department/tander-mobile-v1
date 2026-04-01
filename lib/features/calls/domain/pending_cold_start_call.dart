import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

/// SharedPreferences key for persisted call metadata.
///
/// Written by [CallPushBridge] during background/killed push handling.
/// Read by [ColdStartAcceptor] during app cold-start to reconstruct
/// the incoming call state before Riverpod initializes.
const String kPendingCallMetadataKey = 'pending_call_metadata';

/// Call metadata persisted by [CallPushBridge] for cold-start acceptance.
///
/// When the app is killed and an incoming call push arrives, the background
/// handler persists this metadata to SharedPreferences. On cold start,
/// [ColdStartAcceptor] reads it to reconstruct the call info needed by
/// the engine to complete the connection.
final class PendingColdStartCall {
  const PendingColdStartCall({
    required this.roomId,
    required this.callType,
    required this.callerName,
    required this.callerUserId,
    this.callerPhoto,
    this.callerUsername = '',
    required this.timestamp,
  });

  final String roomId;
  final String callType;
  final String callerName;
  final String callerUserId;
  final String? callerPhoto;
  final String callerUsername;
  final DateTime timestamp;

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

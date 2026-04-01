import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tander_flutter_v3/features/calls/domain/pending_cold_start_call.dart';

// ---------------------------------------------------------------------------
// UUID normalization — deterministic UUID for non-UUID roomIds
// ---------------------------------------------------------------------------

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Deterministic UUID normalization — same input always produces same UUID.
/// Required because CallKit/ConnectionService requires UUID format IDs.
String normalizeToUuid(String id) {
  if (_uuidRegex.hasMatch(id)) return id;

  // XOR-fold bytes into 16 bytes for deterministic hashing
  final bytes = utf8.encode(id);
  final hash = List<int>.filled(16, 0);
  for (var i = 0; i < bytes.length; i++) {
    hash[i % 16] ^= bytes[i];
  }
  // Set UUID version 4 + variant bits
  hash[6] = (hash[6] & 0x0F) | 0x40;
  hash[8] = (hash[8] & 0x3F) | 0x80;

  final hex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

// ---------------------------------------------------------------------------
// CallPushBridge — FCM data-only push → native call UI
// ---------------------------------------------------------------------------

/// Bridges FCM push notifications to native call UI (CallKit/ConnectionService).
///
/// When the app is in the background or killed, incoming calls arrive via FCM
/// data-only pushes. This bridge converts the push payload into
/// [FlutterCallkitIncoming] calls to show the system call UI.
///
/// Push types handled:
/// - `incoming_call` → show native incoming call UI
/// - `call_cancelled` → dismiss native UI
/// - `call_ended` → dismiss native UI
///
/// Ported from legacy `tander-flutter/lib/features/calls/data/push/call_push_bridge.dart`.
abstract final class CallPushBridge {
  /// Handle a background push notification for calls.
  ///
  /// Called from the top-level `handleBackgroundMessage` function.
  /// Firebase sends data as `Map<String, String>` — nested JSON is parsed.
  /// Returns `true` if the push was handled (was a call push).
  static Future<bool> handleBackgroundCallPush(
    Map<String, dynamic> messageData,
  ) async {
    // Firebase background handler sends all values as strings — parse JSON
    final data = _parseFirebaseData(messageData);
    final type = data['type'] as String?;
    if (type == null) return false;

    switch (type) {
      case 'incoming_call':
        return _handleIncomingPush(data);
      case 'call_cancelled':
        return _handleTerminalPush(data, payloadType: 'call_cancelled');
      case 'call_ended':
        return _handleTerminalPush(data, payloadType: 'call_ended');
      default:
        return false;
    }
  }

  /// Show native CallKit/ConnectionService UI for an incoming call.
  ///
  /// Used by both background handler and foreground handler to display
  /// the native call screen (lock screen, notification shade).
  static Future<void> showNativeCallUI({
    required String roomId,
    required String callerName,
    required String callType,
    String? callerPhoto,
  }) async {
    final normalizedId = normalizeToUuid(roomId);

    final params = CallKitParams(
      id: normalizedId,
      nameCaller: callerName,
      avatar: callerPhoto,
      handle: callerName,
      type: callType == 'video' ? 1 : 0,
      duration: 45000, // 45s ring timeout
      textAccept: 'Accept',
      textDecline: 'Decline',
      extra: <String, dynamic>{
        'callType': callType,
        'roomId': roomId,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#FF6B35',
        actionColor: '#14B8A6',
        isShowFullLockedScreen: true,
      ),
      ios: IOSParams(
        iconName: 'TanderCallKitLogo',
        handleType: 'generic',
        supportsVideo: callType == 'video',
        audioSessionMode: callType == 'video' ? 'videoChat' : 'voiceChat',
        audioSessionActive: false,
        configureAudioSession: false,
        audioSessionPreferredSampleRate: 48000.0,
        audioSessionPreferredIOBufferDuration: 0,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
    debugPrint('[CallPushBridge] Showed native call UI: room=$roomId '
        'caller=$callerName type=$callType');
  }

  /// Dismiss native call UI by roomId.
  static Future<void> dismissNativeCallUI(String roomId) async {
    final normalizedId = normalizeToUuid(roomId);
    await FlutterCallkitIncoming.endCall(normalizedId);
    debugPrint('[CallPushBridge] Dismissed native call UI: room=$roomId');
  }

  /// Dismiss all active native call UIs.
  static Future<void> dismissAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
    debugPrint('[CallPushBridge] Dismissed all native call UIs');
  }

  /// Persist call metadata to SharedPreferences for cold-start acceptance.
  static Future<void> persistCallMetadata({
    required String roomId,
    required String callerName,
    required String callType,
    String? callerPhoto,
    required String callerUserId,
    String callerUsername = '',
  }) async {
    try {
      final metadata = jsonEncode({
        'roomId': roomId,
        'callerName': callerName,
        'callType': callType,
        'callerPhoto': callerPhoto,
        'callerUserId': callerUserId,
        'callerUsername': callerUsername,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPendingCallMetadataKey, metadata);
      debugPrint('[CallPushBridge] Persisted call metadata for $roomId');
    } catch (error) {
      debugPrint('[CallPushBridge] Failed to persist metadata: $error');
    }
  }

  /// Clear persisted call metadata.
  static Future<void> clearPersistedMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kPendingCallMetadataKey);
    } catch (_) {
      // Best-effort cleanup
    }
  }

  /// Read persisted call metadata for cold-start acceptance.
  static Future<PendingColdStartCall?> readPersistedMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Pick up writes from background isolate
      final json = prefs.getString(kPendingCallMetadataKey);
      if (json == null) return null;
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PendingColdStartCall.fromMap(map);
    } catch (error) {
      debugPrint('[CallPushBridge] Read metadata failed: $error');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Private handlers
  // ---------------------------------------------------------------------------

  static Future<bool> _handleIncomingPush(Map<String, dynamic> data) async {
    final roomId = _extractRoomId(data);
    if (roomId == null) {
      debugPrint('[CallPushBridge] Missing roomId in incoming call push');
      return false;
    }

    final callerName = data['callerName'] as String? ??
        data['displayName'] as String? ??
        'Unknown Caller';
    final callType = data['callType'] as String? ?? 'audio';
    final callerPhoto =
        data['callerPhoto'] as String? ?? data['profilePhoto'] as String?;
    final callerUserId =
        (data['callerId'] ?? data['userId'] ?? '').toString();
    final callerUsername =
        (data['callerUsername'] ?? data['username'] ?? '').toString();

    debugPrint('[CallPushBridge] Incoming call push: room=$roomId '
        'caller=$callerName type=$callType');

    // Show native call UI
    await showNativeCallUI(
      roomId: roomId,
      callerName: callerName,
      callType: callType,
      callerPhoto: callerPhoto,
    );

    // Persist metadata for cold-start acceptance
    await persistCallMetadata(
      roomId: roomId,
      callerName: callerName,
      callType: callType,
      callerPhoto: callerPhoto,
      callerUserId: callerUserId,
      callerUsername: callerUsername,
    );

    return true;
  }

  static Future<bool> _handleTerminalPush(
    Map<String, dynamic> data, {
    required String payloadType,
  }) async {
    final roomId = _extractRoomId(data);
    if (roomId == null) return false;

    debugPrint(
        '[CallPushBridge] Terminal call push ($payloadType): room=$roomId');

    // Dismiss the native call UI
    await dismissNativeCallUI(roomId);

    // Clear persisted metadata (caller cancelled while app was dead)
    await clearPersistedMetadata();

    return true;
  }

  /// Extract room ID from push data (supports multiple key names).
  static String? _extractRoomId(Map<String, dynamic> data) {
    return data['roomId'] as String? ??
        data['roomName'] as String? ??
        data['room_id'] as String?;
  }

  /// Parse Firebase data map — values arrive as strings, try JSON decode.
  static Map<String, dynamic> _parseFirebaseData(
    Map<String, dynamic> messageData,
  ) {
    final data = <String, dynamic>{};
    for (final entry in messageData.entries) {
      try {
        data[entry.key] = jsonDecode(entry.value as String);
      } catch (_) {
        data[entry.key] = entry.value;
      }
    }
    return data;
  }
}

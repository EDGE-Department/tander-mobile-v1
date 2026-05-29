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

/// Key + TTL for the locally-handled call set. When the user answers /
/// declines / a call ends, we record the callId here so a late incoming-call
/// FCM push (~3s behind the instant WPS path) is suppressed instead of
/// re-raising a stale "Incoming call" notification. Stored in
/// SharedPreferences so the FCM background isolate sees it too.
const _kHandledCallIdsKey = 'tander_handled_call_ids';
const _handledTtlMs = 120 * 1000; // 2 min — ring window + late-push slack

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
  ///
  /// [callId] / [acceptToken] / [declineToken] / [dismissToken] / [callerUserId]
  /// are Phase-5 v2 fields. When present they're forwarded via CallKit's
  /// `extra` dict so the plugin's accept/decline event handlers can route
  /// to `/api/v2/calls/{callId}/{accept,decline,dismiss}-action` instead
  /// of the legacy /api/twilio/video/* path. Null for legacy pushes.
  static Future<void> showNativeCallUI({
    required String roomId,
    required String callerName,
    required String callType,
    String? callerPhoto,
    String? callId,
    String? acceptToken,
    String? declineToken,
    String? dismissToken,
    String? callerUserId,
  }) async {
    final normalizedId = normalizeToUuid(roomId);

    // Suppress stale incoming UI: if this call was already answered / declined
    // / ended locally, a late FCM push (the WPS path is instant; FCM lags ~3s)
    // must NOT re-raise the "Incoming call" notification. Dismiss anything that
    // slipped through, then bail before showing.
    if (callId != null && await _isCallHandled(callId)) {
      debugPrint(
        '[CallPushBridge] Suppressing incoming UI — '
        'call $callId already handled',
      );
      await FlutterCallkitIncoming.endCall(normalizedId);
      return;
    }

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
        'callId': ?callId,
        'acceptToken': ?acceptToken,
        'declineToken': ?declineToken,
        'dismissToken': ?dismissToken,
        'callerUserId': ?callerUserId,
        'isV2': callId != null,
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
    debugPrint(
      '[CallPushBridge] Showed native call UI: room=$roomId '
      'caller=$callerName type=$callType',
    );
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

  /// Record a call as locally handled (answered / declined / ended) so a late
  /// incoming-call FCM push for the same call is suppressed by
  /// [showNativeCallUI] rather than re-raising the notification.
  static Future<void> markCallHandled(String callId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _readHandledMap(prefs);
      map[callId] = DateTime.now().millisecondsSinceEpoch;
      _pruneHandled(map);
      await prefs.setString(_kHandledCallIdsKey, jsonEncode(map));
      debugPrint('[CallPushBridge] Marked call handled: $callId');
    } catch (e) {
      debugPrint('[CallPushBridge] markCallHandled failed: $e');
    }
  }

  static Future<bool> _isCallHandled(String callId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // pick up writes from the main isolate
      final map = _readHandledMap(prefs);
      _pruneHandled(map);
      return map.containsKey(callId);
    } catch (e) {
      debugPrint('[CallPushBridge] _isCallHandled failed: $e');
      return false;
    }
  }

  static Map<String, int> _readHandledMap(SharedPreferences prefs) {
    final raw = prefs.getString(_kHandledCallIdsKey);
    if (raw == null) return <String, int>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return <String, int>{};
    }
  }

  static void _pruneHandled(Map<String, int> map) {
    final cutoff = DateTime.now().millisecondsSinceEpoch - _handledTtlMs;
    map.removeWhere((_, ts) => ts < cutoff);
  }

  /// Persist call metadata to SharedPreferences for cold-start acceptance.
  ///
  /// Optional v2 fields ([callId] / [twilioRoomSid] / [acceptToken] /
  /// [declineToken] / [dismissToken] / [expiresAt]) — null for legacy
  /// payloads, present for Phase 5 v2 pushes. Persisted so a future
  /// native-side fast-path can read them directly from SharedPreferences
  /// without booting Flutter.
  static Future<void> persistCallMetadata({
    required String roomId,
    required String callerName,
    required String callType,
    String? callerPhoto,
    required String callerUserId,
    String callerUsername = '',
    String? callId,
    String? twilioRoomSid,
    String? acceptToken,
    String? declineToken,
    String? dismissToken,
    String? expiresAt,
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
        'callId': ?callId,
        'twilioRoomSid': ?twilioRoomSid,
        'acceptToken': ?acceptToken,
        'declineToken': ?declineToken,
        'dismissToken': ?dismissToken,
        'expiresAt': ?expiresAt,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPendingCallMetadataKey, metadata);
      debugPrint(
        '[CallPushBridge] Persisted call metadata for $roomId'
        '${callId != null ? " (v2 callId=$callId)" : ""}',
      );
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
    // v2 detection — IncomingCallPushListener writes `acceptToken` (opaque
    // 43-char Base64URL) in every Phase 5 push payload. Legacy
    // /api/twilio/video/room pushes don't.
    final isV2 = data['acceptToken'] is String;

    // Real UUID callId is preferred when present (v2 always sends it).
    // Legacy uses session UUID for callId too but its key may be missing.
    final callId = data['callId'] as String?;
    final roomId = _extractRoomId(data) ?? callId;
    if (roomId == null) {
      debugPrint('[CallPushBridge] Missing room/call id in incoming call push');
      return false;
    }

    final callerName =
        data['callerName'] as String? ??
        data['displayName'] as String? ??
        'Unknown Caller';
    final callType = data['callType'] as String? ?? 'audio';
    final callerPhoto =
        data['callerPhoto'] as String? ??
        data['callerPhotoUrl'] as String? ??
        data['profilePhoto'] as String?;
    // v2 uses `callerUserId`; legacy uses `callerId`.
    final callerUserId =
        (data['callerUserId'] ?? data['callerId'] ?? data['userId'] ?? '')
            .toString();
    final callerUsername = (data['callerUsername'] ?? data['username'] ?? '')
        .toString();

    debugPrint(
      '[CallPushBridge] Incoming call push (${isV2 ? "v2" : "legacy"}): '
      'room=$roomId caller=$callerName type=$callType',
    );

    // Show native call UI — v2 fields (callId + opaque action tokens) ride
    // along in CallKit extras so the plugin's accept/decline event handler
    // can route to the v2 action-token endpoints without a Dart-side lookup.
    await showNativeCallUI(
      roomId: roomId,
      callerName: callerName,
      callType: callType,
      callerPhoto: callerPhoto,
      callId: callId,
      acceptToken: data['acceptToken'] as String?,
      declineToken: data['declineToken'] as String?,
      dismissToken: data['dismissToken'] as String?,
      callerUserId: isV2 ? callerUserId : null,
    );

    // Persist metadata for cold-start acceptance. v2 fields preserved so
    // future native fast-path (Stage 4 polish) can read the opaque tokens
    // directly from SharedPreferences without going through Flutter first.
    await persistCallMetadata(
      roomId: roomId,
      callerName: callerName,
      callType: callType,
      callerPhoto: callerPhoto,
      callerUserId: callerUserId,
      callerUsername: callerUsername,
      callId: callId,
      twilioRoomSid: data['twilioRoomSid'] as String?,
      acceptToken: data['acceptToken'] as String?,
      declineToken: data['declineToken'] as String?,
      dismissToken: data['dismissToken'] as String?,
      expiresAt: data['expiresAt'] as String?,
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
      '[CallPushBridge] Terminal call push ($payloadType): room=$roomId',
    );

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

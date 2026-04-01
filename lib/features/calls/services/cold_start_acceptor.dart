import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import 'package:tander_flutter_v3/core/config/env_config.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/calls/domain/pending_cold_start_call.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// Phase A cold-start handler — runs before Riverpod/Session exist.
///
/// When the user taps Accept on a native call notification while the app
/// is killed, this handler:
/// 1. Detects the pending accept via `activeCalls()`
/// 2. Reads persisted call metadata from SharedPreferences
/// 3. Fires an immediate REST accept (caller sees "Connecting...")
/// 4. Stores the pending call in a static field for Phase B
///
/// No Riverpod, no Session, no STOMP — just raw Dio + SecureStorage.
///
/// Ported from legacy `tander-flutter/lib/features/calls/data/native/cold_start_acceptor.dart`.
abstract final class ColdStartAcceptor {
  /// Pending call from cold start. Read by AppShell in Phase B.
  static PendingColdStartCall? _pending;

  /// Check for a cold-start call accept and fire REST accept if found.
  ///
  /// Call this in `main()` before `runApp()`.
  static Future<void> checkAndAccept(SecureStorage secureStorage) async {
    try {
      final action = await _detectNativeAction();
      if (action == null) return;

      final metadata = await CallPushBridge.readPersistedMetadata();
      if (metadata == null) {
        debugPrint(
            '[ColdStart] No persisted metadata for ${action.callId}');
        return;
      }

      // Discard stale calls (>2 min old)
      if (metadata.isStale) {
        debugPrint('[ColdStart] Stale call metadata — discarding');
        await CallPushBridge.clearPersistedMetadata();
        return;
      }

      if (action.isAccepted) {
        debugPrint(
            '[ColdStart] Pending accept: room=${metadata.roomId}');

        // Fire immediate REST accept (best-effort)
        await _fireRestAccept(metadata.roomId, secureStorage);

        // Store for Phase B consumption
        _pending = metadata;
      } else {
        debugPrint(
            '[ColdStart] Pending decline: room=${metadata.roomId}');
        await _fireRestDecline(metadata.roomId, secureStorage);
      }

      // Clear persisted metadata (consumed)
      await CallPushBridge.clearPersistedMetadata();
    } catch (error) {
      debugPrint('[ColdStart] checkAndAccept failed: $error');
    }
  }

  /// Consume the pending call (returns and clears the static field).
  static PendingColdStartCall? consumePending() {
    final pending = _pending;
    _pending = null;
    return pending;
  }

  /// Whether there is a pending cold-start call.
  static bool get hasPending => _pending != null;

  // ---------------------------------------------------------------------------
  // Native action detection
  // ---------------------------------------------------------------------------

  static Future<_DetectedAction?> _detectNativeAction() async {
    // First check immediately
    final immediate = await _pollActiveCalls();
    if (immediate != null) return immediate;

    // Retry after a short delay (OEM-specific timing issues)
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _pollActiveCalls();
  }

  static Future<_DetectedAction?> _pollActiveCalls() async {
    try {
      final calls = await FlutterCallkitIncoming.activeCalls();
      if (calls is! List || calls.isEmpty) return null;

      final call = calls.first;
      if (call is! Map) return null;

      final isAccepted = call['isAccepted'] == true;
      final isDeclined = call['isDeclined'] == true;
      final callId = call['id'] as String?;

      if (callId != null && isAccepted) {
        debugPrint('[ColdStart] Detected accepted call: $callId');
        return _DetectedAction(callId: callId, isAccepted: true);
      }
      if (callId != null && isDeclined) {
        debugPrint('[ColdStart] Detected declined call: $callId');
        return _DetectedAction(callId: callId, isAccepted: false);
      }
    } catch (error) {
      debugPrint('[ColdStart] activeCalls check failed: $error');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // REST actions — fire before STOMP connects
  // ---------------------------------------------------------------------------

  /// Fire REST accept to `/api/twilio/video/accept`.
  ///
  /// Uses raw Dio since Riverpod interceptors aren't initialized yet.
  static Future<void> _fireRestAccept(
    String roomId,
    SecureStorage secureStorage,
  ) async {
    try {
      final token = await _readToken(secureStorage);
      if (token == null) {
        debugPrint('[ColdStart] No JWT — skipping REST accept');
        return;
      }

      final dio = _createDio();
      await dio.post(
        ApiEndpoints.acceptCall,
        data: {'roomName': roomId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint('[ColdStart] REST accept sent for $roomId');
    } catch (error) {
      // Best-effort — caller will still wait for STOMP-based accept
      debugPrint('[ColdStart] REST accept failed (continuing): $error');
    }
  }

  static Future<void> _fireRestDecline(
    String roomId,
    SecureStorage secureStorage,
  ) async {
    try {
      final token = await _readToken(secureStorage);
      if (token == null) {
        debugPrint('[ColdStart] No JWT — skipping REST decline');
        return;
      }

      final dio = _createDio();
      await dio.post(
        ApiEndpoints.declineCall,
        data: {'roomName': roomId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint('[ColdStart] REST decline sent for $roomId');
    } catch (error) {
      debugPrint('[ColdStart] REST decline failed (continuing): $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Future<String?> _readToken(SecureStorage secureStorage) async {
    final result = await secureStorage.readAccessToken();
    return switch (result) {
      Success(value: final token) => token,
      Failure() => null,
    };
  }

  static Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }
}

final class _DetectedAction {
  const _DetectedAction({
    required this.callId,
    required this.isAccepted,
  });

  final String callId;
  final bool isAccepted;
}

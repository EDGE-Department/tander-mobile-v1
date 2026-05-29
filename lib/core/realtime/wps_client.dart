import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tander_flutter_v3/core/contracts/calls_v2_contracts.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/realtime/realtime_negotiate_datasource.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// State of the WPS WebSocket connection.
enum WpsConnectionState {
  /// No connection attempt active. Initial state and post-logout terminal.
  disconnected,

  /// Negotiate in flight or WebSocket handshake in progress.
  connecting,

  /// WebSocket open, receiving events.
  connected,

  /// Connection dropped; backoff timer running before next attempt.
  reconnecting,

  /// Negotiate returned 401. Session is revoked; no more reconnect attempts
  /// until the caller explicitly resets state via [WpsClient.connect].
  revoked,
}

/// Loose envelope shape matching backend `CallEventEnvelope`. Kept
/// permissive so future event types (chat, presence) flow through without
/// a contract change.
typedef WpsEnvelope = Map<String, Object?>;

typedef WpsEventHandler = void Function(WpsEnvelope envelope);
typedef WpsStateListener = void Function(WpsConnectionState state);

/// Azure Web PubSub client — single shared WebSocket subscription.
///
/// Mirrors `tander-web/src/core/realtime/wps-client.ts` with mobile-specific
/// lifecycle integration:
///
/// - **App lifecycle** (Option A per advisor): observes
///   `AppLifecycleState.paused` → marks manualDisconnect + closes the WS.
///   `AppLifecycleState.resumed` → calls [connect] again. WS only exists
///   while the app is in the foreground.
/// - **Idempotency guard**: [connect] is a no-op if already connecting or
///   connected. Prevents thundering-herd when multiple screens defensively
///   call connect during a resume window.
///
/// Lifecycle owner is the auth layer: call [connect] on
/// successful login + bootstrap restore, [disconnect] on logout. The
/// observer handles foreground/background transitions automatically.
///
/// Connection is authenticated via [RealtimeNegotiateDatasource] which
/// returns a short-lived signed token (15min for call-capable devices)
/// embedded in the WS URL.
///
/// Per envelope-version contract: receive-only. Tokens carry no
/// `joinGroup`/`sendToGroup` capability; all publishing is server-only.
final class WpsClient with WidgetsBindingObserver {
  WpsClient({required RealtimeNegotiateDatasource negotiateDatasource})
    : _negotiate = negotiateDatasource {
    WidgetsBinding.instance.addObserver(this);
  }

  // ---------------------------------------------------------------------
  // Tunables (mirror web client where applicable)
  // ---------------------------------------------------------------------

  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _dedupWindow = Duration(seconds: 60);
  static const int _dedupPruneThreshold = 512;

  // ---------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------

  final RealtimeNegotiateDatasource _negotiate;

  WebSocketChannel? _ws;

  // Cancelled in _closeSocket(); the lint can't see across method indirection.
  // ignore: cancel_subscriptions
  StreamSubscription<dynamic>? _wsSub;
  WpsConnectionState _state = WpsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;

  /// Set of active event handlers. Single-call dispatch on incoming msg.
  final Set<WpsEventHandler> _eventHandlers = <WpsEventHandler>{};
  final Set<WpsStateListener> _stateListeners = <WpsStateListener>{};

  /// Recent eventIds (with arrival timestamp) for cross-tab dedup. Pruned
  /// when size > [_dedupPruneThreshold].
  final Map<String, DateTime> _seenEventIds = <String, DateTime>{};

  WpsConnectionState get state => _state;

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Subscribe to incoming envelopes. Returns an unsubscribe closure.
  void Function() addEventListener(WpsEventHandler handler) {
    _eventHandlers.add(handler);
    return () => _eventHandlers.remove(handler);
  }

  /// Subscribe to state transitions. Returns an unsubscribe closure.
  void Function() addStateListener(WpsStateListener listener) {
    _stateListeners.add(listener);
    return () => _stateListeners.remove(listener);
  }

  /// Open the connection. Idempotent — no-op if already connecting or
  /// connected. Safe to call from setSession on bootstrap restore + login,
  /// and from the app lifecycle observer on resume.
  Future<void> connect() async {
    // Idempotency guard — advisor's "thundering-herd on resume" prevention.
    if (_state == WpsConnectionState.connecting ||
        _state == WpsConnectionState.connected) {
      return;
    }

    _cancelPendingReconnect();
    _manualDisconnect = false;
    _setState(WpsConnectionState.connecting);

    try {
      final NegotiateResponseDto negotiated = await _negotiate.negotiate();
      AppLogger.debug(
        'WPS negotiated hub=${negotiated.hubName} device=${negotiated.deviceId}',
        operation: 'WpsClient.connect',
      );
      _openSocket(negotiated.url);
    } on AppException catch (e) {
      if (_isUnauthorized(e)) {
        AppLogger.warning(
          'WPS negotiate → 401, marking revoked',
          operation: 'WpsClient.connect',
        );
        _reconnectAttempts = 0;
        _setState(WpsConnectionState.revoked);
        return;
      }
      AppLogger.warning(
        'WPS negotiate failed, will retry: $e',
        operation: 'WpsClient.connect',
      );
      _scheduleReconnect();
    } on Object catch (e) {
      AppLogger.warning(
        'WPS negotiate threw unexpected: $e',
        operation: 'WpsClient.connect',
      );
      _scheduleReconnect();
    }
  }

  /// Close the connection. Intentional disconnect — no reconnect attempted.
  /// Call from logout / clearSession.
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _cancelPendingReconnect();
    await _closeSocket();
    _setState(WpsConnectionState.disconnected);
    _reconnectAttempts = 0;
  }

  /// Release listeners + observer. Call from app teardown if you ever do
  /// (Flutter apps usually don't — this is here for tests).
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await disconnect();
    _eventHandlers.clear();
    _stateListeners.clear();
    _seenEventIds.clear();
  }

  // ---------------------------------------------------------------------
  // App lifecycle (advisor's Option A)
  // ---------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        AppLogger.debug(
          'app paused — closing WPS',
          operation: 'WpsClient.didChangeAppLifecycleState',
        );
        // Pause = treat as manual close. Native push wakes us for incoming
        // calls; WPS reconnects on resume.
        unawaited(disconnect());
        break;
      case AppLifecycleState.resumed:
        AppLogger.debug(
          'app resumed — reconnecting WPS',
          operation: 'WpsClient.didChangeAppLifecycleState',
        );
        unawaited(connect());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  void _openSocket(String url) {
    final WebSocketChannel channel = WebSocketChannel.connect(Uri.parse(url));
    _ws = channel;

    _wsSub = channel.stream.listen(
      (message) {
        if (message is! String) return;
        WpsEnvelope parsed;
        try {
          final decoded = jsonDecode(message);
          if (decoded is! Map) return;
          parsed = decoded.cast<String, Object?>();
        } on Object {
          AppLogger.warning(
            'WPS non-JSON message dropped',
            operation: 'WpsClient._openSocket',
          );
          return;
        }
        AppLogger.debug(
          'WPS recv type=${parsed['type']} callId=${parsed['callId']}',
          operation: 'WpsClient._openSocket',
        );
        _dedupAndDispatch(parsed);
      },
      onError: (Object error) {
        AppLogger.warning(
          'WPS socket error: $error',
          operation: 'WpsClient._openSocket',
        );
      },
      onDone: () {
        final int? code = channel.closeCode;
        AppLogger.debug(
          'WPS closed code=$code reason=${channel.closeReason ?? '(empty)'}',
          operation: 'WpsClient._openSocket',
        );
        _ws = null;
        _wsSub = null;
        if (_manualDisconnect) {
          _setState(WpsConnectionState.disconnected);
          return;
        }
        // Unexpected close — could be transient network or server force-
        // disconnect. Re-negotiate; a 401 there confirms revoke.
        _scheduleReconnect();
      },
      cancelOnError: false,
    );

    // Open is signaled via ready future; web_socket_channel doesn't expose
    // an explicit onopen, but emission begins on first stream activity.
    // Mark connected eagerly — the first non-JSON message will warn but
    // not error.
    _reconnectAttempts = 0;
    _setState(WpsConnectionState.connected);
  }

  Future<void> _closeSocket() async {
    final ws = _ws;
    _ws = null;
    final sub = _wsSub;
    _wsSub = null;
    if (sub != null) {
      await sub.cancel();
    }
    if (ws != null) {
      try {
        await ws.sink.close(1000, 'client-disconnect');
      } on Object {
        // best-effort
      }
    }
  }

  void _scheduleReconnect() {
    _cancelPendingReconnect();
    final int attempt = _reconnectAttempts;
    final int delayMs = math.min(
      _baseReconnectDelay.inMilliseconds * (1 << attempt),
      _maxReconnectDelay.inMilliseconds,
    );
    _reconnectAttempts += 1;
    _setState(WpsConnectionState.reconnecting);
    AppLogger.debug(
      'WPS reconnect attempt=$_reconnectAttempts delay=${delayMs}ms',
      operation: 'WpsClient._scheduleReconnect',
    );
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      _reconnectTimer = null;
      unawaited(connect());
    });
  }

  void _cancelPendingReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _setState(WpsConnectionState next) {
    if (_state == next) return;
    _state = next;
    for (final listener in _stateListeners) {
      try {
        listener(next);
      } on Object catch (e) {
        AppLogger.warning(
          'WPS state listener threw: $e',
          operation: 'WpsClient._setState',
        );
      }
    }
  }

  void _dedupAndDispatch(WpsEnvelope envelope) {
    final dynamic rawId = envelope['eventId'];
    if (rawId is String && rawId.isNotEmpty) {
      final now = DateTime.now();
      final prior = _seenEventIds[rawId];
      if (prior != null && now.difference(prior) < _dedupWindow) {
        return;
      }
      _seenEventIds[rawId] = now;
      if (_seenEventIds.length > _dedupPruneThreshold) {
        final cutoff = now.subtract(_dedupWindow);
        _seenEventIds.removeWhere((_, ts) => ts.isBefore(cutoff));
      }
    }
    for (final handler in _eventHandlers) {
      try {
        handler(envelope);
      } on Object catch (e) {
        AppLogger.warning(
          'WPS event handler threw: $e',
          operation: 'WpsClient._dedupAndDispatch',
        );
      }
    }
  }

  bool _isUnauthorized(AppException e) {
    // NetworkExceptionHandler maps Dio 401 → AuthException.
    return e is AuthException;
  }
}

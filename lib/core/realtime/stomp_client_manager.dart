import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:tander_flutter_v3/core/config/env_config.dart';
import 'package:tander_flutter_v3/core/storage/secure_storage.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

enum StompConnectionState { disconnected, connecting, connected, reconnecting, error }

/// Callback invoked when a STOMP message arrives, with the parsed JSON body.
typedef StompMessageHandler = void Function(Map<String, Object?> body);

/// Cancels a subscription previously created via [StompClientManager.subscribe].
typedef StompUnsubscribeCallback = void Function();

final class _SubscriptionEntry {
  _SubscriptionEntry({required this.destination, required this.handler});

  final String destination;
  final StompMessageHandler handler;

  /// The live STOMP unsubscribe handle. Null when the subscription is pending
  /// (queued before the client connected or after a reconnect cleared handles).
  StompUnsubscribe? activeHandle;
}

// ---------------------------------------------------------------------------
// Singleton STOMP client manager
// ---------------------------------------------------------------------------

/// Global STOMP WebSocket client that mirrors the web's `stomp-client.ts`.
///
/// Lifecycle rules:
///   - Call [connect] after authentication succeeds.
///   - Call [disconnect] **only** on explicit logout. NEVER on widget unmount.
///   - Subscriptions registered before [connect] completes are queued and
///     applied automatically once the connection is established.
///   - On reconnect, every active subscription is re-created transparently.
final class StompClientManager {
  StompClientManager._();

  static final StompClientManager instance = StompClientManager._();

  static const String _tag = 'StompClientManager';

  // ---------------------------------------------------------------------------
  // Connection constants
  // ---------------------------------------------------------------------------

  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _heartbeatInterval = Duration(seconds: 4);
  static const Duration _presenceHeartbeatInterval = Duration(seconds: 20);
  static const String _presenceDestination = '/app/presence.heartbeat';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  StompConnectionState _connectionState = StompConnectionState.disconnected;
  StompConnectionState get connectionState => _connectionState;

  StompClient? _client;
  SecureStorage? _secureStorage;
  int _reconnectAttempts = 0;
  Timer? _heartbeatTimer;

  /// Listeners notified on every connection state change.
  final List<void Function(StompConnectionState)> _stateListeners = [];

  /// All subscriptions (pending + active), keyed by an opaque identity object
  /// so the same handler can be subscribed to multiple destinations.
  final List<_SubscriptionEntry> _subscriptions = [];

  // ---------------------------------------------------------------------------
  // State listeners
  // ---------------------------------------------------------------------------

  void addStateListener(void Function(StompConnectionState) listener) {
    _stateListeners.add(listener);
  }

  void removeStateListener(void Function(StompConnectionState) listener) {
    _stateListeners.remove(listener);
  }

  // ---------------------------------------------------------------------------
  // Connect
  // ---------------------------------------------------------------------------

  /// Open the STOMP connection with the given [accessToken].
  ///
  /// [secureStorage] is required so that reconnects can read a fresh token
  /// from secure storage instead of re-using the original (possibly expired)
  /// token.
  void connect({
    required String accessToken,
    required SecureStorage secureStorage,
  }) {
    if (_client != null && _client!.connected) {
      AppLogger.debug(
        'Already connected — ignoring duplicate connect call',
        operation: _tag,
      );
      return;
    }

    _secureStorage = secureStorage;
    _setConnectionState(StompConnectionState.connecting);

    _client = StompClient(
      config: StompConfig(
        url: EnvConfig.wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        reconnectDelay: _baseReconnectDelay,
        heartbeatIncoming: _heartbeatInterval,
        heartbeatOutgoing: _heartbeatInterval,

        beforeConnect: _onBeforeConnect,

        onConnect: _onConnected,
        onStompError: _onStompError,
        onDisconnect: _onDisconnected,
        onWebSocketDone: _onWebSocketDone,
        onWebSocketError: _onWebSocketError,
      ),
    );

    _client!.activate();
    AppLogger.info('STOMP client activated', operation: _tag);
  }

  // ---------------------------------------------------------------------------
  // Disconnect (logout only)
  // ---------------------------------------------------------------------------

  void disconnect() {
    _stopHeartbeat();
    _client?.deactivate();
    _client = null;
    _subscriptions.clear();
    _reconnectAttempts = 0;
    _setConnectionState(StompConnectionState.disconnected);
    AppLogger.info('Disconnected and cleared all subscriptions', operation: _tag);
  }

  // ---------------------------------------------------------------------------
  // Subscribe
  // ---------------------------------------------------------------------------

  /// Subscribe to [destination]. Returns a teardown function that removes the
  /// subscription both from the live STOMP session and from the internal
  /// pending list (so it will NOT be re-created on reconnect).
  StompUnsubscribeCallback subscribe(
    String destination,
    StompMessageHandler handler,
  ) {
    final entry = _SubscriptionEntry(destination: destination, handler: handler);
    _subscriptions.add(entry);

    // If already connected, subscribe immediately.
    if (_client != null && _client!.connected) {
      _activateSubscription(entry);
    }

    return () {
      _deactivateSubscription(entry);
      _subscriptions.remove(entry);
    };
  }

  // ---------------------------------------------------------------------------
  // Send
  // ---------------------------------------------------------------------------

  void send(String destination, Map<String, Object?> body) {
    if (_client == null || !_client!.connected) {
      AppLogger.warning(
        'Cannot send — STOMP not connected',
        operation: _tag,
        context: {'destination': destination},
      );
      return;
    }

    _client!.send(
      destination: destination,
      body: jsonEncode(body),
    );
  }

  // ---------------------------------------------------------------------------
  // STOMP lifecycle callbacks
  // ---------------------------------------------------------------------------

  Future<void> _onBeforeConnect() async {
    final storage = _secureStorage;
    if (storage == null) return;

    final tokenResult = await storage.readAccessToken();
    final freshToken = tokenResult.valueOrNull;

    if (freshToken == null || freshToken.isEmpty) {
      AppLogger.warning(
        'No access token found during beforeConnect — reconnect will likely fail',
        operation: _tag,
      );
      return;
    }

    // Patch the connect headers with the fresh token so the next CONNECT frame
    // authenticates with the latest credential.
    _client?.config.stompConnectHeaders?['Authorization'] = 'Bearer $freshToken';

    AppLogger.debug(
      'Refreshed auth header before connect attempt '
      '(attempt #$_reconnectAttempts)',
      operation: _tag,
    );
  }

  void _onConnected(StompFrame frame) {
    _reconnectAttempts = 0;
    _setConnectionState(StompConnectionState.connected);
    _resubscribeAll();
    _startHeartbeat();
    AppLogger.info('STOMP connected', operation: _tag);
  }

  void _onStompError(StompFrame frame) {
    _setConnectionState(StompConnectionState.error);
    AppLogger.error(
      'STOMP protocol error',
      operation: _tag,
      context: {'body': frame.body ?? 'no body'},
    );
  }

  void _onDisconnected(StompFrame frame) {
    _stopHeartbeat();
    _setConnectionState(StompConnectionState.disconnected);
    AppLogger.info('STOMP disconnected (DISCONNECT frame received)', operation: _tag);
  }

  void _onWebSocketDone() {
    _stopHeartbeat();
    _reconnectAttempts += 1;

    // Clear active handles — they are invalidated after the socket closes.
    // _resubscribeAll() will recreate them on the next onConnect.
    for (final entry in _subscriptions) {
      entry.activeHandle = null;
    }

    _setConnectionState(StompConnectionState.reconnecting);

    AppLogger.warning(
      'WebSocket closed — scheduling reconnect',
      operation: _tag,
      context: {'attempt': _reconnectAttempts.toString()},
    );

    // If the user has logged out (no token), stop the reconnect loop.
    // Fire-and-forget is intentional — the callback is synchronous and we
    // cannot await here. Errors are caught inside the method.
    unawaited(_checkTokenAndStopIfLoggedOut());
  }

  // The stomp_dart_client typedef uses `dynamic` for the error parameter.
  // We accept it as-is and forward to AppLogger which takes `Object?`.
  void _onWebSocketError(dynamic error) {
    AppLogger.error(
      'WebSocket transport error',
      operation: _tag,
      error: error is Object ? error : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Token guard — stop reconnecting when logged out
  // ---------------------------------------------------------------------------

  Future<void> _checkTokenAndStopIfLoggedOut() async {
    try {
      final storage = _secureStorage;
      if (storage == null) return;

      final tokenResult = await storage.readAccessToken();
      final token = tokenResult.valueOrNull;

      if (token == null || token.isEmpty) {
        AppLogger.info(
          'No access token in storage — stopping reconnect loop (user logged out)',
          operation: _tag,
        );
        _client?.deactivate();
        _client = null;
        _reconnectAttempts = 0;
        _setConnectionState(StompConnectionState.disconnected);
      }
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Failed to check token during reconnect guard',
        operation: _tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription helpers
  // ---------------------------------------------------------------------------

  void _activateSubscription(_SubscriptionEntry entry) {
    if (_client == null || !_client!.connected) return;

    entry.activeHandle = _client!.subscribe(
      destination: entry.destination,
      callback: (StompFrame frame) {
        final rawBody = frame.body;
        if (rawBody == null || rawBody.isEmpty) return;

        final parsed = jsonDecode(rawBody);
        if (parsed is Map<String, Object?>) {
          entry.handler(parsed);
        } else {
          AppLogger.warning(
            'Received non-object STOMP body — skipping handler',
            operation: _tag,
            context: {'destination': entry.destination},
          );
        }
      },
    );
  }

  void _deactivateSubscription(_SubscriptionEntry entry) {
    entry.activeHandle?.call();
    entry.activeHandle = null;
  }

  /// Re-subscribe all registered handlers after a successful reconnect.
  void _resubscribeAll() {
    if (_client == null || !_client!.connected) return;

    for (final entry in _subscriptions) {
      if (entry.activeHandle != null) continue;
      _activateSubscription(entry);
    }

    AppLogger.debug(
      'Re-subscribed ${_subscriptions.length} handler(s) after connect',
      operation: _tag,
    );
  }

  // ---------------------------------------------------------------------------
  // Presence heartbeat
  // ---------------------------------------------------------------------------

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_presenceHeartbeatInterval, (_) {
      send(_presenceDestination, <String, Object?>{});
    });
    AppLogger.debug('Presence heartbeat started', operation: _tag);
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Internal state management
  // ---------------------------------------------------------------------------

  void _setConnectionState(StompConnectionState newState) {
    if (_connectionState == newState) return;

    _connectionState = newState;
    AppLogger.info(
      'Connection state → ${newState.name}',
      operation: _tag,
    );

    for (final listener in List.of(_stateListeners)) {
      listener(newState);
    }
  }
}

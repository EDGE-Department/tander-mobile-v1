import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';

/// Real-time connection-event subscriptions over STOMP.
///
/// Backend publishes a minimal `{kind: ...}` payload to
/// `/topic/connections.{userId}` whenever the user's request/sent/connected
/// lists change for any reason (peer accepts, peer cancels, peer unmatches,
/// new like received, etc). Clients use it as a refresh trigger.
final class ConnectionStompDatasource {
  const ConnectionStompDatasource();

  static const String _tag = 'ConnectionStompDatasource';

  /// Subscribe to connection events for [userId]. Calls [onEvent] with the
  /// event kind (e.g. "match", "accept", "remove", "unmatch", "request",
  /// "decline", "cancel", "block", or "refresh") whenever the lists change.
  ///
  /// Returns a teardown function — invoke on dispose.
  StompUnsubscribeCallback subscribeToConnectionEvents(
    String userId, {
    required void Function(String kind) onEvent,
  }) {
    final destination = '/topic/connections.$userId';
    AppLogger.debug(
      'Subscribing to connection events',
      operation: '$_tag.subscribeToConnectionEvents',
      context: {'destination': destination},
    );

    return StompClientManager.instance.subscribe(destination, (
      Map<String, Object?> body,
    ) {
      final kind = body['kind']?.toString() ?? 'refresh';
      onEvent(kind);
    });
  }
}

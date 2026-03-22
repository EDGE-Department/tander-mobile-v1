/// Remote datasource for all connection (match) API calls.
///
/// Returns raw [Response] objects so the repository layer can map DTOs
/// to domain models and wrap errors in [Result].
library;

import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

final class ConnectionRemoteDatasource {
  const ConnectionRemoteDatasource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'ConnectionRemoteDatasource';

  // -----------------------------------------------------------------------
  // Fetch lists
  // -----------------------------------------------------------------------

  /// Fetches incoming connection requests (others who liked the current user).
  Future<Response<List<Object?>>> fetchIncomingRequests() {
    AppLogger.debug(
      'Fetching incoming requests',
      operation: '$_tag.fetchIncomingRequests',
    );

    return _dioClient.get<List<Object?>>(ApiEndpoints.matchesReceived);
  }

  /// Fetches outgoing connection requests sent by the current user.
  Future<Response<List<Object?>>> fetchSentRequests() {
    AppLogger.debug(
      'Fetching sent requests',
      operation: '$_tag.fetchSentRequests',
    );

    return _dioClient.get<List<Object?>>(ApiEndpoints.matchesSent);
  }

  /// Fetches all accepted connections (friends).
  Future<Response<List<Object?>>> fetchConnections() {
    AppLogger.debug(
      'Fetching connections',
      operation: '$_tag.fetchConnections',
    );

    return _dioClient.get<List<Object?>>(ApiEndpoints.matchesConnected);
  }

  // -----------------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------------

  /// Accepts an incoming connection request identified by [matchId].
  Future<Response<Map<String, Object?>>> acceptRequest({
    required int matchId,
  }) {
    AppLogger.debug(
      'Accepting connection request',
      operation: '$_tag.acceptRequest',
      context: {'matchId': matchId},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.matchAccept(matchId),
    );
  }

  /// Declines an incoming connection request identified by [matchId].
  Future<Response<Map<String, Object?>>> declineRequest({
    required int matchId,
  }) {
    AppLogger.debug(
      'Declining connection request',
      operation: '$_tag.declineRequest',
      context: {'matchId': matchId},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.matchDecline(matchId),
    );
  }

  /// Cancels a sent connection request identified by [matchId].
  Future<void> cancelRequest({required int matchId}) async {
    AppLogger.debug(
      'Cancelling sent request',
      operation: '$_tag.cancelRequest',
      context: {'matchId': matchId},
    );

    await _dioClient.delete<void>(ApiEndpoints.matchCancel(matchId));
  }

  /// Removes an existing connection identified by [matchId].
  Future<void> removeConnection({required int matchId}) async {
    AppLogger.debug(
      'Removing connection',
      operation: '$_tag.removeConnection',
      context: {'matchId': matchId},
    );

    await _dioClient.delete<void>(ApiEndpoints.matchRemove(matchId));
  }
}

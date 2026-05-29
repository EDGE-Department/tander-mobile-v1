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
  Future<Response<dynamic>> fetchIncomingRequests() {
    AppLogger.debug(
      'Fetching incoming requests',
      operation: '$_tag.fetchIncomingRequests',
    );

    return _dioClient.get<dynamic>(ApiEndpoints.matchesReceived);
  }

  /// Fetches outgoing connection requests sent by the current user.
  Future<Response<dynamic>> fetchSentRequests() {
    AppLogger.debug(
      'Fetching sent requests',
      operation: '$_tag.fetchSentRequests',
    );

    return _dioClient.get<dynamic>(ApiEndpoints.matchesSent);
  }

  /// Fetches all accepted connections (friends).
  Future<Response<dynamic>> fetchConnections() {
    AppLogger.debug(
      'Fetching connections',
      operation: '$_tag.fetchConnections',
    );

    return _dioClient.get<dynamic>(ApiEndpoints.matchesConnected);
  }

  // -----------------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------------

  /// Accepts an incoming connection request identified by [matchId].
  Future<Response<Map<String, Object?>>> acceptRequest({
    required String matchId,
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
    required String matchId,
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
  Future<void> cancelRequest({required String matchId}) async {
    AppLogger.debug(
      'Cancelling sent request',
      operation: '$_tag.cancelRequest',
      context: {'matchId': matchId},
    );

    await _dioClient.delete<void>(ApiEndpoints.matchCancel(matchId));
  }

  /// Removes an existing connection identified by [matchId].
  Future<void> removeConnection({required String matchId}) async {
    AppLogger.debug(
      'Removing connection',
      operation: '$_tag.removeConnection',
      context: {'matchId': matchId},
    );

    await _dioClient.delete<void>(ApiEndpoints.matchRemove(matchId));
  }

  // -----------------------------------------------------------------------
  // Block / Unmatch
  // -----------------------------------------------------------------------

  /// Fetches the list of blocked users.
  Future<Response<dynamic>> fetchBlockedUsers() {
    AppLogger.debug(
      'Fetching blocked users',
      operation: '$_tag.fetchBlockedUsers',
    );

    return _dioClient.get<dynamic>(ApiEndpoints.connectionsBlocked);
  }

  /// Blocks a user by their connection ID.
  Future<Response<Map<String, Object?>>> blockUser({
    required String connectionId,
  }) {
    AppLogger.debug(
      'Blocking user',
      operation: '$_tag.blockUser',
      context: {'connectionId': connectionId},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.connectionBlock(connectionId),
    );
  }

  /// Unmatches (unfriends) a user by their connection ID.
  Future<void> unmatchUser({required String connectionId}) async {
    AppLogger.debug(
      'Unmatching user',
      operation: '$_tag.unmatchUser',
      context: {'connectionId': connectionId},
    );

    await _dioClient.delete<void>(ApiEndpoints.connectionUnmatch(connectionId));
  }
}

/// Concrete [ConnectionRepository] backed by [ConnectionRemoteDatasource].
///
/// Every public method catches all exceptions and wraps them in [Failure]
/// so callers never see raw throws.
library;

import 'package:tander_flutter_v3/core/contracts/connection_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/mappers/connection_mapper.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/connection/data/datasources/connection_remote_datasource.dart';
import 'package:tander_flutter_v3/features/connection/domain/repositories/connection_repository.dart';

final class ConnectionRepositoryImpl implements ConnectionRepository {
  const ConnectionRepositoryImpl({
    required ConnectionRemoteDatasource remoteDatasource,
    required String currentUserId,
  })  : _remoteDatasource = remoteDatasource,
        _currentUserId = currentUserId;

  final ConnectionRemoteDatasource _remoteDatasource;
  final String _currentUserId;

  static const String _tag = 'ConnectionRepositoryImpl';

  // -----------------------------------------------------------------------
  // Fetch lists
  // -----------------------------------------------------------------------

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>>
      fetchIncomingRequests() {
    return _runSafe('fetchIncomingRequests', () async {
      final response = await _remoteDatasource.fetchIncomingRequests();
      final dtos = _parseMatchDtoList(response.data);
      return mapListToResult(
        dtos,
        (dto) => mapMatchDtoToConnectionSummary(
          dto,
          _currentUserId,
          expectedState: ConnectionRelationshipState.pendingIncoming,
        ),
      );
    });
  }

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchSentRequests() {
    return _runSafe('fetchSentRequests', () async {
      final response = await _remoteDatasource.fetchSentRequests();
      final dtos = _parseMatchDtoList(response.data);
      return mapListToResult(
        dtos,
        (dto) => mapMatchDtoToConnectionSummary(
          dto,
          _currentUserId,
          expectedState: ConnectionRelationshipState.pendingOutgoing,
        ),
      );
    });
  }

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchConnections() {
    return _runSafe('fetchConnections', () async {
      final response = await _remoteDatasource.fetchConnections();
      final dtos = _parseMatchDtoList(response.data);
      return mapListToResult(
        dtos,
        (dto) => mapMatchDtoToConnectionSummary(
          dto,
          _currentUserId,
          expectedState: ConnectionRelationshipState.connected,
        ),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------------

  @override
  Future<Result<void>> acceptRequest({required String matchId}) {
    return _runSafe('acceptRequest', () async {
      await _remoteDatasource.acceptRequest(matchId: matchId);
    });
  }

  @override
  Future<Result<void>> declineRequest({required String matchId}) {
    return _runSafe('declineRequest', () async {
      await _remoteDatasource.declineRequest(matchId: matchId);
    });
  }

  @override
  Future<Result<void>> cancelRequest({required String matchId}) {
    return _runSafe('cancelRequest', () async {
      await _remoteDatasource.cancelRequest(matchId: matchId);
    });
  }

  @override
  Future<Result<void>> removeConnection({required String matchId}) {
    return _runSafe('removeConnection', () async {
      await _remoteDatasource.removeConnection(matchId: matchId);
    });
  }

  // -----------------------------------------------------------------------
  // Block / Unmatch
  // -----------------------------------------------------------------------

  @override
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchBlockedUsers() {
    return _runSafe('fetchBlockedUsers', () async {
      final response = await _remoteDatasource.fetchBlockedUsers();
      final dtos = _parseMatchDtoList(response.data);
      return mapListToResult(
        dtos,
        (dto) => mapMatchDtoToConnectionSummary(dto, _currentUserId),
      );
    });
  }

  @override
  Future<Result<void>> blockUser({required String connectionId}) {
    return _runSafe('blockUser', () async {
      await _remoteDatasource.blockUser(connectionId: connectionId);
    });
  }

  @override
  Future<Result<void>> unmatchUser({required String connectionId}) {
    return _runSafe('unmatchUser', () async {
      await _remoteDatasource.unmatchUser(connectionId: connectionId);
    });
  }

  // -----------------------------------------------------------------------
  // Parsing
  // -----------------------------------------------------------------------

  List<MatchDto> _parseMatchDtoList(dynamic rawData) {
    if (rawData == null) return const [];

    // Handle direct list response
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((json) => MatchDto.fromJson(Map<String, Object?>.from(json)))
          .toList();
    }

    // Handle wrapped responses from backend
    if (rawData is Map<String, dynamic>) {
      // Backend wraps in { success: true, data: [...] }
      final data = rawData['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map((json) => MatchDto.fromJson(Map<String, Object?>.from(json)))
            .toList();
      }

      // Spring-paginated response: { "content": [...], ... }
      final content = rawData['content'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map((json) => MatchDto.fromJson(Map<String, Object?>.from(json)))
            .toList();
      }
    }

    return const [];
  }

  // -----------------------------------------------------------------------
  // Error wrapper
  // -----------------------------------------------------------------------

  Future<Result<TValue>> _runSafe<TValue>(
    String operationName,
    Future<TValue> Function() action,
  ) async {
    try {
      final value = await action();
      return Success(value);
    } on AppException catch (exception) {
      return Failure(exception);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        '$operationName failed',
        operation: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      return Failure(
        UnknownException(
          message: '$operationName failed: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

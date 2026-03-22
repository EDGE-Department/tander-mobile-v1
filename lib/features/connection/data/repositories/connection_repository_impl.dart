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
        (dto) => mapMatchDtoToConnectionSummary(dto, _currentUserId),
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
        (dto) => mapMatchDtoToConnectionSummary(dto, _currentUserId),
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
        (dto) => mapMatchDtoToConnectionSummary(dto, _currentUserId),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------------

  @override
  Future<Result<void>> acceptRequest({required String matchId}) {
    return _runSafe('acceptRequest', () async {
      await _remoteDatasource.acceptRequest(matchId: int.parse(matchId));
    });
  }

  @override
  Future<Result<void>> declineRequest({required String matchId}) {
    return _runSafe('declineRequest', () async {
      await _remoteDatasource.declineRequest(matchId: int.parse(matchId));
    });
  }

  @override
  Future<Result<void>> cancelRequest({required String matchId}) {
    return _runSafe('cancelRequest', () async {
      await _remoteDatasource.cancelRequest(matchId: int.parse(matchId));
    });
  }

  @override
  Future<Result<void>> removeConnection({required String matchId}) {
    return _runSafe('removeConnection', () async {
      await _remoteDatasource.removeConnection(matchId: int.parse(matchId));
    });
  }

  // -----------------------------------------------------------------------
  // Parsing
  // -----------------------------------------------------------------------

  List<MatchDto> _parseMatchDtoList(List<Object?>? rawList) {
    if (rawList == null || rawList.isEmpty) return const [];

    return rawList
        .whereType<Map<String, Object?>>()
        .map(MatchDto.fromJson)
        .toList();
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

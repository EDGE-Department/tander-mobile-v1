import 'package:tander_flutter_v3/core/contracts/discover_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:tander_flutter_v3/features/discover/domain/repositories/discover_repository.dart';

/// Coordinates [DiscoverRemoteDatasource] to fulfil the
/// [DiscoverRepository] contract.
///
/// Every public method catches all exceptions and wraps them in
/// [Failure] so callers never see raw throws.
final class DiscoverRepositoryImpl implements DiscoverRepository {
  const DiscoverRepositoryImpl({
    required DiscoverRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final DiscoverRemoteDatasource _remoteDatasource;

  static const String _tag = 'DiscoverRepositoryImpl';

  // -----------------------------------------------------------------------
  // Fetch profiles
  // -----------------------------------------------------------------------

  @override
  Future<Result<PaginatedCandidates>> fetchProfiles({
    int page = 0,
    int size = 20,
    DiscoveryFiltersDto? filters,
  }) {
    return _runSafe('fetchProfiles', () async {
      final response = await _remoteDatasource.fetchProfiles(
        page: page,
        size: size,
        filters: filters,
      );
      final body = _requireResponseBody(response.data, 'discovery profiles');
      return _mapPaginatedResponse(body);
    });
  }

  @override
  Future<Result<DiscoveryCandidate>> fetchProfile({required int userId}) {
    return _runSafe('fetchProfile', () async {
      final response = await _remoteDatasource.fetchProfile(userId: userId);
      final body = _requireResponseBody(response.data, 'discovery profile');
      final dto = DiscoveryProfileDto.fromJson(body);
      return _mapCandidate(dto);
    });
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------

  @override
  Future<Result<void>> sendConnectionRequest({required int targetUserId}) {
    return _runSafe('sendConnectionRequest', () async {
      await _remoteDatasource.sendConnectionRequest(
        targetUserId: targetUserId,
      );
    });
  }

  @override
  Future<Result<void>> passOnProfile({required int targetUserId}) {
    return _runSafe('passOnProfile', () async {
      await _remoteDatasource.passOnProfile(targetUserId: targetUserId);
    });
  }

  // -----------------------------------------------------------------------
  // Mappers
  // -----------------------------------------------------------------------

  PaginatedCandidates _mapPaginatedResponse(Map<String, Object?> body) {
    final contentRaw = body['content'];
    final List<Object?> contentList =
        contentRaw is List<Object?> ? contentRaw : <Object?>[];

    final candidates = contentList
        .whereType<Map<String, Object?>>()
        .map((json) => _mapCandidate(DiscoveryProfileDto.fromJson(json)))
        .toList();

    final int currentPage = _safeInt(body['number']);
    final int totalPages = _safeInt(body['totalPages']);
    final int totalElements = _safeInt(body['totalElements']);
    final bool isLastPage = body['last'] == true;

    return PaginatedCandidates(
      candidates: candidates,
      currentPage: currentPage,
      totalPages: totalPages,
      totalElements: totalElements,
      isLastPage: isLastPage,
    );
  }

  DiscoveryCandidate _mapCandidate(DiscoveryProfileDto dto) {
    final displayName = dto.displayName ?? dto.username;

    return DiscoveryCandidate(
      userId: dto.userId.toString(),
      username: dto.username,
      firstName: displayName,
      age: dto.age,
      city: dto.city,
      country: dto.country,
      bio: dto.bio,
      profilePhotoUrl: dto.profilePhotoUrl,
      additionalPhotos: dto.additionalPhotos ?? const [],
      interests: dto.interests ?? const [],
      isOnline: dto.online,
      hasExistingConnection: dto.matched,
    );
  }

  int _safeInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return 0;
  }

  // -----------------------------------------------------------------------
  // Private helpers
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

  Map<String, Object?> _requireResponseBody(
    Map<String, Object?>? body,
    String endpointLabel,
  ) {
    if (body == null) {
      throw FormatException(
        'Empty response body from $endpointLabel endpoint',
      );
    }
    return body;
  }
}

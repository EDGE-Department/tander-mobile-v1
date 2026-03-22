import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/contracts/discover_contracts.dart';
import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

/// All discovery-related API calls, delegating HTTP to [DioClient].
///
/// Methods return raw [Response] objects or `void` so the repository layer
/// can map DTOs to domain models and wrap errors in [Result].
final class DiscoverRemoteDatasource {
  const DiscoverRemoteDatasource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'DiscoverRemoteDatasource';

  // -----------------------------------------------------------------------
  // Discovery profiles
  // -----------------------------------------------------------------------

  /// Fetches a paginated list of discovery profiles.
  ///
  /// [page] is zero-indexed. [size] defaults to 20.
  /// Optional [filters] narrows the result set by age, distance, gender.
  Future<Response<Map<String, Object?>>> fetchProfiles({
    int page = 0,
    int size = 20,
    DiscoveryFiltersDto? filters,
  }) {
    final Map<String, Object> queryParameters = {
      'page': page,
      'size': size,
      'verifiedOnly': false,
      'minAge': filters?.minAge ?? 18,
    };

    if (filters != null) {
      queryParameters['maxAge'] = filters.maxAge;
      queryParameters['maxDistanceKm'] = filters.maxDistanceKm;
      if (filters.genderPreference != null) {
        queryParameters['genderPreference'] = filters.genderPreference!;
      }
    }

    AppLogger.debug(
      'Fetching discovery profiles',
      operation: '$_tag.fetchProfiles',
      context: {'page': page, 'size': size},
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.discoveryProfiles,
      queryParameters: queryParameters,
    );
  }

  /// Fetches a single discovery profile by [userId].
  Future<Response<Map<String, Object?>>> fetchProfile({
    required int userId,
  }) {
    AppLogger.debug(
      'Fetching discovery profile',
      operation: '$_tag.fetchProfile',
      context: {'userId': userId},
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.discoveryProfile(userId),
    );
  }

  /// Sends a RIGHT swipe (like / connection request) for [targetUserId].
  Future<void> sendConnectionRequest({required int targetUserId}) async {
    AppLogger.debug(
      'Sending connection request',
      operation: '$_tag.sendConnectionRequest',
      context: {'targetUserId': targetUserId},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.swipe,
      data: {
        'targetUserId': targetUserId,
        'direction': 'RIGHT',
      },
    );
  }

  /// Sends a LEFT swipe (pass) for [targetUserId].
  Future<void> passOnProfile({required int targetUserId}) async {
    AppLogger.debug(
      'Passing on profile',
      operation: '$_tag.passOnProfile',
      context: {'targetUserId': targetUserId},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.swipe,
      data: {
        'targetUserId': targetUserId,
        'direction': 'LEFT',
      },
    );
  }
}

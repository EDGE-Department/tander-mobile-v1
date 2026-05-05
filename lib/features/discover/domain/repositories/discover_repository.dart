import 'package:tander_flutter_v3/core/contracts/discover_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Contract for all discovery operations.
///
/// Implementations live in the data layer and may use Dio or any other
/// infrastructure concern. The domain and presentation layers only know
/// this interface.
abstract interface class DiscoverRepository {
  /// Fetches a paginated list of discovery candidates.
  ///
  /// Returns a [PaginatedCandidates] with the list and pagination metadata.
  Future<Result<PaginatedCandidates>> fetchProfiles({
    int page = 0,
    int size = 20,
    DiscoveryFiltersDto? filters,
  });

  /// Fetches a single discovery candidate by [userId].
  Future<Result<DiscoveryCandidate>> fetchProfile({required String userId});

  /// Sends a like / connection request for the given [targetUserId].
  Future<Result<void>> sendConnectionRequest({required String targetUserId});

  /// Passes on (skips) the given [targetUserId].
  Future<Result<void>> passOnProfile({required String targetUserId});
}

/// Wrapper for a paginated list of [DiscoveryCandidate] results.
final class PaginatedCandidates {
  const PaginatedCandidates({
    required this.candidates,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.isLastPage,
  });

  final List<DiscoveryCandidate> candidates;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isLastPage;

  @override
  String toString() => 'PaginatedCandidates('
      'count: ${candidates.length}, '
      'page: $currentPage/$totalPages)';
}

/// Contract for all connection operations.
///
/// Implementations live in the data layer. The domain and presentation
/// layers depend only on this interface, never on concrete infrastructure.
library;

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

abstract interface class ConnectionRepository {
  /// Fetches incoming connection requests.
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchIncomingRequests();

  /// Fetches outgoing (sent) connection requests.
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchSentRequests();

  /// Fetches all accepted connections (friends).
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchConnections();

  /// Accepts an incoming connection request.
  Future<Result<void>> acceptRequest({required String matchId});

  /// Declines an incoming connection request.
  Future<Result<void>> declineRequest({required String matchId});

  /// Cancels a sent connection request.
  Future<Result<void>> cancelRequest({required String matchId});

  /// Removes an existing connection (unfriend).
  Future<Result<void>> removeConnection({required String matchId});

  /// Fetches the list of blocked users.
  Future<Result<PaginatedResult<ConnectionSummary>>> fetchBlockedUsers();

  /// Blocks a user (hides them from discovery, chat, etc.).
  Future<Result<void>> blockUser({required String connectionId});

  /// Unmatches (unfriends) a user.
  Future<Result<void>> unmatchUser({required String connectionId});
}

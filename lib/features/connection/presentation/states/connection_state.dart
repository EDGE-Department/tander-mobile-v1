/// Sealed state hierarchy for the connection screen.
///
/// Exhaustive `switch` is enforced by the compiler — adding a new subclass
/// without updating all consumers triggers a compile-time error.
library;

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

sealed class ConnectionState {
  const ConnectionState();
}

/// Initial loading — all three lists are being fetched.
final class ConnectionLoading extends ConnectionState {
  const ConnectionLoading();
}

/// All three lists loaded successfully.
final class ConnectionLoaded extends ConnectionState {
  const ConnectionLoaded({
    required this.incomingRequests,
    required this.sentRequests,
    required this.connectedFriends,
  });

  /// Incoming requests from other users.
  final PaginatedResult<ConnectionSummary> incomingRequests;

  /// Outgoing requests the current user has sent.
  final PaginatedResult<ConnectionSummary> sentRequests;

  /// Accepted connections (friends).
  final PaginatedResult<ConnectionSummary> connectedFriends;

  /// Convenience counts for the tab bar badges.
  int get pendingCount => incomingRequests.items.length;
  int get sentCount => sentRequests.items.length;
  int get friendsCount => connectedFriends.items.length;

  ConnectionLoaded copyWith({
    PaginatedResult<ConnectionSummary>? incomingRequests,
    PaginatedResult<ConnectionSummary>? sentRequests,
    PaginatedResult<ConnectionSummary>? connectedFriends,
  }) {
    return ConnectionLoaded(
      incomingRequests: incomingRequests ?? this.incomingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      connectedFriends: connectedFriends ?? this.connectedFriends,
    );
  }
}

/// At least one of the three fetch calls failed.
final class ConnectionError extends ConnectionState {
  const ConnectionError({required this.exception});

  final AppException exception;
}

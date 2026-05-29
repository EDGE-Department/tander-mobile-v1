/// Connection domain models — consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
///
/// UI always says "Connection", never "Match".
library;

import 'package:flutter/foundation.dart';

// ── Relationship State ───────────────────────────────────────

/// Describes the relationship between the current user and another user.
enum ConnectionRelationshipState {
  pendingIncoming,
  pendingOutgoing,
  connected,
  none,
}

// ── Connection Summary ───────────────────────────────────────

@immutable
class ConnectionSummary {
  const ConnectionSummary({
    required this.connectionId,
    required this.otherUserId,
    required this.otherUsername,
    required this.relationshipState,
    required this.createdAt,
    this.otherPhotoUrl,
    this.otherAge,
    this.otherCity,
    this.conversationId,
  });

  final String connectionId;
  final String otherUserId;
  final String otherUsername;
  final String? otherPhotoUrl;
  final int? otherAge;
  final String? otherCity;
  final ConnectionRelationshipState relationshipState;
  final String? conversationId;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionSummary &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId;

  @override
  int get hashCode => connectionId.hashCode;

  @override
  String toString() =>
      'ConnectionSummary('
      'id: $connectionId, '
      'user: $otherUsername, '
      'state: ${relationshipState.name})';
}

// ── Paginated Result ─────────────────────────────────────────

@immutable
class PaginatedResult<TItem> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  final List<TItem> items;
  final int totalCount;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginatedResult &&
          runtimeType == other.runtimeType &&
          totalCount == other.totalCount &&
          currentPage == other.currentPage &&
          pageSize == other.pageSize;

  @override
  int get hashCode => Object.hash(totalCount, currentPage, pageSize);

  @override
  String toString() =>
      'PaginatedResult('
      'page: $currentPage/$totalPages, '
      'items: ${items.length}/$totalCount)';
}

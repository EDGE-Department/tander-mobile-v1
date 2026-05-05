/// Maps connection DTOs to domain models.
///
/// Backend uses "match" terminology; the UI always says "connection".
/// This mapper is the single translation point between the two.
library;

import 'package:tander_flutter_v3/core/contracts/connection_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/shared/utils/photo_url.dart';

/// Converts a [MatchDto] into a [ConnectionSummary] domain model.
///
/// The [currentUserId] parameter is reserved for future use when the
/// backend provides richer direction metadata.
ConnectionSummary mapMatchDtoToConnectionSummary(
  MatchDto dto,
  String currentUserId, {
  ConnectionRelationshipState? expectedState,
}) {
  return ConnectionSummary(
    connectionId: dto.id,
    otherUserId: dto.otherUserId,
    otherUsername: (dto.otherDisplayName?.isNotEmpty ?? false)
        ? dto.otherDisplayName!
        : dto.otherUsername ?? 'User',
    otherPhotoUrl: resolvePhotoUrl(dto.otherProfilePhotoUrl),
    otherAge: dto.otherAge,
    otherCity: null,
    relationshipState: expectedState ?? _computeRelationshipState(dto),
    conversationId: null,
    createdAt: DateTime.tryParse(dto.matchedAt ?? '') ?? DateTime.now(),
  );
}

/// Derives [ConnectionRelationshipState] from DTO status.
ConnectionRelationshipState _computeRelationshipState(MatchDto dto) {
  return switch (dto.status) {
    'ACCEPTED' => ConnectionRelationshipState.connected,
    'PENDING' => ConnectionRelationshipState.pendingIncoming,
    'BLOCKED' => ConnectionRelationshipState.none,
    _ => ConnectionRelationshipState.none,
  };
}

/// Converts a [SpringPageDto] of DTOs into a [PaginatedResult] of models.
///
/// The [mapItem] callback transforms each DTO element individually.
PaginatedResult<TModel> mapSpringPageToResult<TDto, TModel>(
  SpringPageDto<TDto> page,
  TModel Function(TDto dto) mapItem,
) {
  return PaginatedResult<TModel>(
    items: page.content.map(mapItem).toList(),
    totalCount: page.totalElements,
    totalPages: page.totalPages,
    currentPage: page.number,
    pageSize: page.size,
    hasNextPage: !page.last,
    hasPreviousPage: !page.first,
  );
}

/// Wraps a plain list of DTOs into a single-page [PaginatedResult].
///
/// Used when the backend returns a flat JSON array rather than a
/// Spring-style paginated envelope.
PaginatedResult<TModel> mapListToResult<TDto, TModel>(
  List<TDto> list,
  TModel Function(TDto dto) mapItem,
) {
  return PaginatedResult<TModel>(
    items: list.map(mapItem).toList(),
    totalCount: list.length,
    totalPages: 1,
    currentPage: 0,
    pageSize: list.length,
    hasNextPage: false,
    hasPreviousPage: false,
  );
}

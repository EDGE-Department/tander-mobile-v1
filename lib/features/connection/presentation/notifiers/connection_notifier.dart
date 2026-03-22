/// State management for the connection screen.
///
/// Manages three parallel lists (incoming, sent, connected), handles
/// accept/decline/cancel/remove mutations, and triggers auto-refetch
/// after each mutation so the UI stays in sync.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/connection/domain/repositories/connection_repository.dart';
import 'package:tander_flutter_v3/features/connection/presentation/providers/connection_providers.dart';
import 'package:tander_flutter_v3/features/connection/presentation/states/connection_state.dart';

// ── Provider ────────────────────────────────────────────────────────────

final connectionNotifierProvider =
    NotifierProvider<ConnectionNotifier, ConnectionState>(
  ConnectionNotifier.new,
);

// ── Notifier ────────────────────────────────────────────────────────────

final class ConnectionNotifier extends Notifier<ConnectionState> {
  late final ConnectionRepository _repository;

  static const String _tag = 'ConnectionNotifier';

  /// ID of the connection currently being mutated, used to show per-item
  /// loading indicators in the UI.
  String? _mutatingConnectionId;
  String? get mutatingConnectionId => _mutatingConnectionId;

  @override
  ConnectionState build() {
    _repository = ref.read(connectionRepositoryProvider);

    Future.microtask(loadAll);

    return const ConnectionLoading();
  }

  // -----------------------------------------------------------------------
  // Load all three lists in parallel
  // -----------------------------------------------------------------------

  Future<void> loadAll() async {
    state = const ConnectionLoading();

    final results = await (
      _repository.fetchIncomingRequests(),
      _repository.fetchSentRequests(),
      _repository.fetchConnections(),
    ).wait;

    final incomingResult = results.$1;
    final sentResult = results.$2;
    final connectedResult = results.$3;

    // If any of the three fails, surface the first error.
    final firstFailure = incomingResult.exceptionOrNull ??
        sentResult.exceptionOrNull ??
        connectedResult.exceptionOrNull;

    if (firstFailure != null) {
      state = ConnectionError(exception: firstFailure);
      AppLogger.error(
        'Failed to load connections',
        operation: _tag,
        error: firstFailure,
      );
      return;
    }

    state = ConnectionLoaded(
      incomingRequests: incomingResult.valueOrNull ?? _emptyPage(),
      sentRequests: sentResult.valueOrNull ?? _emptyPage(),
      connectedFriends: connectedResult.valueOrNull ?? _emptyPage(),
    );

    AppLogger.debug(
      'Loaded connections',
      operation: _tag,
      context: {
        'incoming': incomingResult.valueOrNull?.items.length ?? 0,
        'sent': sentResult.valueOrNull?.items.length ?? 0,
        'friends': connectedResult.valueOrNull?.items.length ?? 0,
      },
    );
  }

  // -----------------------------------------------------------------------
  // Mutations
  // -----------------------------------------------------------------------

  /// Accepts an incoming request and removes it from the list optimistically.
  Future<void> acceptRequest(String connectionId) async {
    _mutatingConnectionId = connectionId;
    _removeFromIncoming(connectionId);

    final acceptResult =
        await _repository.acceptRequest(matchId: connectionId);

    _mutatingConnectionId = null;

    acceptResult.when(
      success: (_) {
        AppLogger.debug('Accepted $connectionId', operation: _tag);
        Future.microtask(loadAll);
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to accept request $connectionId',
          operation: _tag,
          error: exception,
        );
        Future.microtask(loadAll);
      },
    );
  }

  /// Declines an incoming request and removes it from the list optimistically.
  Future<void> declineRequest(String connectionId) async {
    _mutatingConnectionId = connectionId;
    _removeFromIncoming(connectionId);

    final declineResult =
        await _repository.declineRequest(matchId: connectionId);

    _mutatingConnectionId = null;

    declineResult.when(
      success: (_) {
        AppLogger.debug('Declined $connectionId', operation: _tag);
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to decline request $connectionId',
          operation: _tag,
          error: exception,
        );
        Future.microtask(loadAll);
      },
    );
  }

  /// Cancels a sent request and removes it from the list optimistically.
  Future<void> cancelRequest(String connectionId) async {
    _mutatingConnectionId = connectionId;
    _removeFromSent(connectionId);

    final cancelResult =
        await _repository.cancelRequest(matchId: connectionId);

    _mutatingConnectionId = null;

    cancelResult.when(
      success: (_) {
        AppLogger.debug('Cancelled $connectionId', operation: _tag);
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to cancel request $connectionId',
          operation: _tag,
          error: exception,
        );
        Future.microtask(loadAll);
      },
    );
  }

  /// Removes an existing connection and removes it from the list.
  Future<void> removeConnection(String connectionId) async {
    _mutatingConnectionId = connectionId;
    _removeFromFriends(connectionId);

    final removeResult =
        await _repository.removeConnection(matchId: connectionId);

    _mutatingConnectionId = null;

    removeResult.when(
      success: (_) {
        AppLogger.debug('Removed $connectionId', operation: _tag);
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to remove connection $connectionId',
          operation: _tag,
          error: exception,
        );
        Future.microtask(loadAll);
      },
    );
  }

  // -----------------------------------------------------------------------
  // Optimistic removal helpers
  // -----------------------------------------------------------------------

  void _removeFromIncoming(String connectionId) {
    final currentState = state;
    if (currentState is! ConnectionLoaded) return;

    final updatedItems = currentState.incomingRequests.items
        .where((connection) => connection.connectionId != connectionId)
        .toList();

    state = currentState.copyWith(
      incomingRequests: PaginatedResult<ConnectionSummary>(
        items: updatedItems,
        totalCount: updatedItems.length,
        totalPages: 1,
        currentPage: 0,
        pageSize: updatedItems.length,
        hasNextPage: false,
        hasPreviousPage: false,
      ),
    );
  }

  void _removeFromSent(String connectionId) {
    final currentState = state;
    if (currentState is! ConnectionLoaded) return;

    final updatedItems = currentState.sentRequests.items
        .where((connection) => connection.connectionId != connectionId)
        .toList();

    state = currentState.copyWith(
      sentRequests: PaginatedResult<ConnectionSummary>(
        items: updatedItems,
        totalCount: updatedItems.length,
        totalPages: 1,
        currentPage: 0,
        pageSize: updatedItems.length,
        hasNextPage: false,
        hasPreviousPage: false,
      ),
    );
  }

  void _removeFromFriends(String connectionId) {
    final currentState = state;
    if (currentState is! ConnectionLoaded) return;

    final updatedItems = currentState.connectedFriends.items
        .where((connection) => connection.connectionId != connectionId)
        .toList();

    state = currentState.copyWith(
      connectedFriends: PaginatedResult<ConnectionSummary>(
        items: updatedItems,
        totalCount: updatedItems.length,
        totalPages: 1,
        currentPage: 0,
        pageSize: updatedItems.length,
        hasNextPage: false,
        hasPreviousPage: false,
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  PaginatedResult<ConnectionSummary> _emptyPage() {
    return const PaginatedResult<ConnectionSummary>(
      items: [],
      totalCount: 0,
      totalPages: 1,
      currentPage: 0,
      pageSize: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}

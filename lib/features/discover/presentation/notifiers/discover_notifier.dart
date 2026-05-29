import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/discover_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/contracts/models/profile_models.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/discover/domain/repositories/discover_repository.dart';
import 'package:tander_flutter_v3/features/discover/presentation/providers/discover_providers.dart';
import 'package:tander_flutter_v3/features/discover/presentation/states/discover_state.dart';
import 'package:tander_flutter_v3/features/profile/presentation/providers/user_settings_provider.dart';

/// Threshold: auto-fetch next page when fewer than this many remain.
const int _refetchThreshold = 3;

/// Default page size sent to the API.
const int _defaultPageSize = 20;

// ─── Provider ──────────────────────────────────────────────────────────

final discoverNotifierProvider =
    NotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);

// ─── Notifier ──────────────────────────────────────────────────────────

/// Manages the discover card stack, like/pass actions, pagination,
/// and auto-refetch when the remaining stack runs low.
final class DiscoverNotifier extends Notifier<DiscoverState> {
  // Not `late final` — Notifier.build() runs again on every ref.invalidate,
  // and re-assigning a `late final` throws LateInitializationError.
  late DiscoverRepository _repository;

  static const String _tag = 'DiscoverNotifier';

  DiscoveryFiltersDto? _activeFilters;

  @override
  DiscoverState build() {
    _repository = ref.read(discoverRepositoryProvider);

    // Seed filters from persisted user settings if already loaded so
    // age/distance survive an app restart instead of resetting to "all".
    final initialSettings = ref.read(userSettingsProvider).valueOrNull;
    if (initialSettings != null) {
      _activeFilters = _filtersFromSettings(initialSettings, _activeFilters);
    }

    // React to settings changes (initial async load, or updates from another
    // surface like the settings screen) and reload with the new filter window.
    ref.listen<AsyncValue<UserSettings>>(userSettingsProvider, (_, next) {
      next.whenData((settings) {
        final fresh = _filtersFromSettings(settings, _activeFilters);
        if (!_filtersMatch(fresh, _activeFilters)) {
          _activeFilters = fresh;
          Future.microtask(loadProfiles);
        }
      });
    });

    // Auto-fetch profiles on first access.
    Future.microtask(loadProfiles);

    return const DiscoverLoading();
  }

  static DiscoveryFiltersDto _filtersFromSettings(
    UserSettings s,
    DiscoveryFiltersDto? carry,
  ) {
    return DiscoveryFiltersDto(
      minAge: s.discoveryMinAge,
      maxAge: s.discoveryMaxAge,
      maxDistanceKm: s.discoveryMaxDistanceKm,
      // genderPreference is not yet persisted server-side — keep whatever
      // the user chose this session so toggling settings doesn't drop it.
      genderPreference: carry?.genderPreference,
      lookingFor: carry?.lookingFor,
    );
  }

  static bool _filtersMatch(DiscoveryFiltersDto a, DiscoveryFiltersDto? b) {
    if (b == null) return false;
    return a.minAge == b.minAge &&
        a.maxAge == b.maxAge &&
        a.maxDistanceKm == b.maxDistanceKm &&
        a.genderPreference == b.genderPreference &&
        a.lookingFor == b.lookingFor;
  }

  // -----------------------------------------------------------------------
  // Load / refresh
  // -----------------------------------------------------------------------

  /// Loads the first page of profiles, replacing any existing state.
  Future<void> loadProfiles() async {
    state = const DiscoverLoading();

    final fetchResult = await _repository.fetchProfiles(
      page: 0,
      size: _defaultPageSize,
      filters: _activeFilters,
    );

    fetchResult.when(
      success: (paginated) {
        if (paginated.candidates.isEmpty) {
          state = const DiscoverEmpty();
        } else {
          state = DiscoverLoaded(
            profiles: paginated.candidates,
            currentIndex: 0,
            currentPage: paginated.currentPage,
            isLastPage: paginated.isLastPage,
          );
        }
        AppLogger.debug(
          'Loaded ${paginated.candidates.length} discovery profiles',
          operation: _tag,
        );
      },
      failure: (exception) {
        state = DiscoverError(exception: exception);
        AppLogger.error(
          'Failed to load discovery profiles',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Card actions
  // -----------------------------------------------------------------------

  /// Likes the current profile and advances the stack.
  Future<void> likeCurrentProfile() async {
    final currentState = state;
    if (currentState is! DiscoverLoaded) return;

    final candidate = currentState.currentCandidate;
    if (candidate == null) return;

    _advanceStack(currentState);

    // Fire-and-forget: send the request in the background.
    final sendResult = await _repository.sendConnectionRequest(
      targetUserId: candidate.userId,
    );

    sendResult.when(
      success: (_) {
        AppLogger.debug('Liked profile ${candidate.userId}', operation: _tag);
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to send connection request',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Passes on the current profile and advances the stack.
  Future<void> passCurrentProfile() async {
    final currentState = state;
    if (currentState is! DiscoverLoaded) return;

    final candidate = currentState.currentCandidate;
    if (candidate == null) return;

    _advanceStack(currentState);

    final passResult = await _repository.passOnProfile(
      targetUserId: candidate.userId,
    );

    passResult.when(
      success: (_) {
        AppLogger.debug(
          'Passed on profile ${candidate.userId}',
          operation: _tag,
        );
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to pass on profile',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Filters
  // -----------------------------------------------------------------------

  /// Updates the active filters and reloads profiles from page 0.
  Future<void> applyFilters(DiscoveryFiltersDto? filters) async {
    _activeFilters = filters;
    await loadProfiles();
  }

  /// Returns the currently active filters.
  DiscoveryFiltersDto? get activeFilters => _activeFilters;

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  void _advanceStack(DiscoverLoaded currentState) {
    final nextIndex = currentState.currentIndex + 1;

    if (nextIndex >= currentState.profiles.length) {
      if (currentState.isLastPage) {
        state = const DiscoverEmpty();
      } else {
        state = currentState.copyWith(
          currentIndex: nextIndex,
          isRefetching: true,
        );
        Future.microtask(_fetchNextPage);
      }
      return;
    }

    state = currentState.copyWith(currentIndex: nextIndex);

    // Auto-refetch when running low.
    final remaining = currentState.profiles.length - nextIndex;
    if (remaining < _refetchThreshold && !currentState.isLastPage) {
      Future.microtask(_fetchNextPage);
    }
  }

  Future<void> _fetchNextPage() async {
    final currentState = state;
    if (currentState is! DiscoverLoaded) return;
    if (currentState.isRefetching || currentState.isLastPage) return;

    state = currentState.copyWith(isRefetching: true);

    final nextPage = currentState.currentPage + 1;
    final fetchResult = await _repository.fetchProfiles(
      page: nextPage,
      size: _defaultPageSize,
      filters: _activeFilters,
    );

    final latestState = state;
    if (latestState is! DiscoverLoaded) return;

    fetchResult.when(
      success: (paginated) {
        final mergedProfiles = [
          ...latestState.profiles,
          ...paginated.candidates,
        ];

        if (mergedProfiles.length <= latestState.currentIndex) {
          state = const DiscoverEmpty();
        } else {
          state = latestState.copyWith(
            profiles: mergedProfiles,
            currentPage: paginated.currentPage,
            isLastPage: paginated.isLastPage,
            isRefetching: false,
          );
        }

        AppLogger.debug(
          'Fetched page $nextPage with ${paginated.candidates.length} profiles',
          operation: _tag,
        );
      },
      failure: (exception) {
        state = latestState.copyWith(isRefetching: false);
        AppLogger.error(
          'Failed to fetch next page',
          operation: _tag,
          error: exception,
        );
      },
    );
  }
}

// ─── Single profile provider ──────────────────────────────────────────

/// Provider for fetching a single [DiscoveryCandidate] by user ID.
///
/// Used by the discover profile screen to load detailed data.
final discoverProfileProvider = FutureProvider.family
    .autoDispose<DiscoveryCandidate, String>((ref, userId) async {
      final repository = ref.read(discoverRepositoryProvider);
      final fetchResult = await repository.fetchProfile(userId: userId);

      return fetchResult.when(
        success: (candidate) => candidate,
        failure: (exception) => throw exception,
      );
    });

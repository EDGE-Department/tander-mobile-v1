import 'package:tander_flutter_v3/core/contracts/models/discover_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

/// Sealed state hierarchy for the discover UI.
///
/// Using a sealed class guarantees exhaustive `switch` -- the compiler
/// will error if a new subclass is added without updating every consumer.
sealed class DiscoverState {
  const DiscoverState();
}

/// Initial loading — profiles are being fetched for the first time.
final class DiscoverLoading extends DiscoverState {
  const DiscoverLoading();
}

/// Profiles loaded successfully — the card stack is ready.
final class DiscoverLoaded extends DiscoverState {
  const DiscoverLoaded({
    required this.profiles,
    required this.currentIndex,
    required this.currentPage,
    required this.isLastPage,
    this.isRefetching = false,
  });

  /// All fetched candidates (may span multiple pages).
  final List<DiscoveryCandidate> profiles;

  /// Index of the top card in the stack.
  final int currentIndex;

  /// Last successfully fetched page (zero-indexed).
  final int currentPage;

  /// Whether the last page has been reached.
  final bool isLastPage;

  /// True while a background page fetch is in progress.
  final bool isRefetching;

  /// How many unseen profiles remain in the stack.
  int get remainingCount => profiles.length - currentIndex;

  /// The current top-of-stack candidate, or `null` if exhausted.
  DiscoveryCandidate? get currentCandidate =>
      currentIndex < profiles.length ? profiles[currentIndex] : null;

  /// Up to three candidates for the visible card stack.
  List<DiscoveryCandidate> get visibleStack {
    final int start = currentIndex;
    final int end = (start + 3).clamp(0, profiles.length);
    return profiles.sublist(start, end);
  }

  DiscoverLoaded copyWith({
    List<DiscoveryCandidate>? profiles,
    int? currentIndex,
    int? currentPage,
    bool? isLastPage,
    bool? isRefetching,
  }) {
    return DiscoverLoaded(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      currentPage: currentPage ?? this.currentPage,
      isLastPage: isLastPage ?? this.isLastPage,
      isRefetching: isRefetching ?? this.isRefetching,
    );
  }
}

/// All profiles have been swiped through — the stack is empty.
final class DiscoverEmpty extends DiscoverState {
  const DiscoverEmpty();
}

/// Profile fetch failed with a typed exception.
final class DiscoverError extends DiscoverState {
  const DiscoverError({required this.exception});

  final AppException exception;
}

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

/// Active wellness panel overlay type.
enum TandyActivePanel {
  breathe,
  meditate,
  support,
  psychiatrist,
}

/// Sealed state hierarchy for the Tandy AI screen.
sealed class TandyState {
  const TandyState();
}

/// Initial loading -- conversation is being fetched.
final class TandyLoading extends TandyState {
  const TandyLoading();
}

/// Conversation loaded successfully.
final class TandyLoaded extends TandyState {
  const TandyLoaded({
    required this.thread,
    required this.greeting,
    this.isSending = false,
    this.sendError,
    this.activePanel,
  });

  /// The current conversation thread.
  final TandyThread thread;

  /// Greeting text and suggestion chips.
  final TandyGreeting greeting;

  /// True while a message is being sent.
  final bool isSending;

  /// Non-null when the last send operation failed.
  final String? sendError;

  /// Currently active wellness panel overlay.
  final TandyActivePanel? activePanel;

  /// Convenience: all messages in the thread.
  List<TandyMessage> get messages => thread.messages;

  /// Whether to show the empty state (no messages).
  bool get showEmptyState => messages.isEmpty;

  TandyLoaded copyWith({
    TandyThread? thread,
    TandyGreeting? greeting,
    bool? isSending,
    String? Function()? sendError,
    TandyActivePanel? Function()? activePanel,
  }) {
    return TandyLoaded(
      thread: thread ?? this.thread,
      greeting: greeting ?? this.greeting,
      isSending: isSending ?? this.isSending,
      sendError: sendError != null ? sendError() : this.sendError,
      activePanel: activePanel != null ? activePanel() : this.activePanel,
    );
  }
}

/// Conversation fetch failed with a typed exception.
final class TandyError extends TandyState {
  const TandyError({required this.exception});

  final AppException exception;
}

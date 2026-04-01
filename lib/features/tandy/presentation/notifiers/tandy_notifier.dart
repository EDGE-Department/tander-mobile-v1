import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/tandy/domain/repositories/tandy_repository.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/providers/tandy_providers.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/states/tandy_state.dart';

// ─── Provider ──────────────────────────────────────────────────────────

final tandyNotifierProvider =
    NotifierProvider<TandyNotifier, TandyState>(TandyNotifier.new);

// ─── Notifier ──────────────────────────────────────────────────────────

/// Manages the Tandy conversation state: loading, sending messages
/// (with optimistic appends), clearing, and wellness panel navigation.
final class TandyNotifier extends Notifier<TandyState> {
  late final TandyRepository _repository;

  static const String _tag = 'TandyNotifier';

  @override
  TandyState build() {
    _repository = ref.read(tandyRepositoryProvider);

    // Auto-fetch on first access.
    Future.microtask(loadConversation);

    return const TandyLoading();
  }

  // -----------------------------------------------------------------------
  // Load
  // -----------------------------------------------------------------------

  /// Loads the conversation and greeting in parallel.
  Future<void> loadConversation() async {
    state = const TandyLoading();

    final results = await Future.wait([
      _repository.fetchConversation(),
      _repository.fetchGreeting(),
    ]);

    final threadResult = results[0];
    final greetingResult = results[1];

    // Both must succeed for a loaded state.
    final thread = threadResult.valueOrNull;
    final greeting = greetingResult.valueOrNull;

    if (thread != null) {
      state = TandyLoaded(
        thread: thread as TandyThread,
        greeting: greeting is TandyGreeting
            ? greeting
            : const TandyGreeting(
                greeting: 'How are you feeling today?',
                suggestions: <String>[],
              ),
      );
    } else {
      final exception = threadResult.exceptionOrNull;
      if (exception != null) {
        state = TandyError(exception: exception);
      }
    }
  }

  // -----------------------------------------------------------------------
  // Send message
  // -----------------------------------------------------------------------

  /// Sends a message with optimistic UI: appends a temporary user message
  /// immediately, then replaces it with the server response.
  Future<void> sendMessage(String text) async {
    final currentState = state;
    if (currentState is! TandyLoaded) return;
    if (currentState.isSending) return;

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // Optimistic append
    final optimisticMessage = TandyMessage(
      messageId: 'opt-${DateTime.now().millisecondsSinceEpoch}',
      role: TandyMessageRole.user,
      body: trimmedText,
      structuredBlocks: const <TandyStructuredBlock>[],
      sentAt: DateTime.now(),
      isCardExpanded: false,
      safetyNotices: const <String>[],
    );

    final optimisticThread = TandyThread(
      conversationId: currentState.thread.conversationId,
      createdAt: currentState.thread.createdAt,
      language: currentState.thread.language,
      messages: [...currentState.messages, optimisticMessage],
    );

    state = currentState.copyWith(
      thread: optimisticThread,
      isSending: true,
      sendError: () => null,
      suggestBreathingPanel: false,
    );

    final sendResult = await _repository.sendMessage(message: trimmedText);

    sendResult.when(
      success: (result) {
        final loadedState = state;
        if (loadedState is! TandyLoaded) return;

        // Remove optimistic messages, append real ones.
        final confirmedMessages = loadedState.messages
            .where((message) => !message.messageId.startsWith('opt-'))
            .toList()
          ..add(result.userMessage)
          ..add(result.assistantMessage);

        final updatedThread = TandyThread(
          conversationId: loadedState.thread.conversationId,
          createdAt: loadedState.thread.createdAt,
          language: loadedState.thread.language,
          messages: confirmedMessages,
        );

        final shouldSuggestBreathing = result.suggestBreathing ||
            (result.redirectAction != null &&
                result.redirectAction!.startsWith('breathing:'));

        state = loadedState.copyWith(
          thread: updatedThread,
          isSending: false,
          suggestBreathingPanel: shouldSuggestBreathing,
        );
      },
      failure: (exception) {
        AppLogger.error(
          'Failed to send Tandy message',
          operation: _tag,
          error: exception,
        );

        final loadedState = state;
        if (loadedState is! TandyLoaded) return;

        final errorMessage = switch (exception) {
          NetworkException() =>
            'No internet connection. Please check your connection and try again.',
          ServerException() => exception.message,
          AuthException() =>
            'Your session has expired. Please sign in again.',
          AppException() => exception.userMessage,
        };

        state = loadedState.copyWith(
          isSending: false,
          sendError: () => errorMessage,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Breathing suggestion
  // -----------------------------------------------------------------------

  void dismissBreathingSuggestion() {
    final currentState = state;
    if (currentState is! TandyLoaded) return;
    state = currentState.copyWith(suggestBreathingPanel: false);
  }

  // -----------------------------------------------------------------------
  // Clear conversation
  // -----------------------------------------------------------------------

  Future<void> clearConversation() async {
    final clearResult = await _repository.clearConversation();

    clearResult.when(
      success: (_) => loadConversation(),
      failure: (exception) {
        AppLogger.error(
          'Failed to clear Tandy conversation',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Panel management
  // -----------------------------------------------------------------------

  void setActivePanel(TandyActivePanel? panel) {
    final currentState = state;
    if (currentState is! TandyLoaded) return;
    state = currentState.copyWith(activePanel: () => panel);
  }

  void closePanel() => setActivePanel(null);

  // -----------------------------------------------------------------------
  // Dismiss send error
  // -----------------------------------------------------------------------

  void dismissSendError() {
    final currentState = state;
    if (currentState is! TandyLoaded) return;
    state = currentState.copyWith(sendError: () => null);
  }
}

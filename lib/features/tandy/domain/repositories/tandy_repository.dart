import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

/// Contract for all Tandy AI operations.
///
/// Implementations live in the data layer. The domain and presentation
/// layers only know this interface.
abstract interface class TandyRepository {
  /// Fetches the current conversation thread.
  Future<Result<TandyThread>> fetchConversation();

  /// Fetches a personalized greeting with suggestion chips.
  Future<Result<TandyGreeting>> fetchGreeting();

  /// Sends a message and returns the enriched result containing both
  /// user and assistant messages plus metadata.
  Future<Result<TandySendResult>> sendMessage({
    required String message,
    String? language,
  });

  /// Clears the entire Tandy conversation.
  Future<Result<void>> clearConversation();

  /// Sets the preferred language for Tandy responses.
  Future<Result<void>> setLanguage({required String language});

  /// Toggles the expand/collapse state of a structured card.
  Future<Result<void>> expandCard({
    required int messageId,
    required bool isExpanded,
  });
}

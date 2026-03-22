import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    printer: kDebugMode
        ? PrettyPrinter(
            methodCount: 4,
            errorMethodCount: 8,
            lineLength: 80,
            printEmojis: false,
          )
        : LogfmtPrinter(),
    level: kDebugMode ? Level.debug : Level.info,
  );

  static void debug(
    String message, {
    String? operation,
    Map<String, Object>? context,
  }) {
    _logger.d(_formatMessage(message, operation: operation, context: context));
  }

  static void info(
    String message, {
    String? operation,
    Map<String, Object>? context,
  }) {
    _logger.i(_formatMessage(message, operation: operation, context: context));
  }

  static void warning(
    String message, {
    String? operation,
    Map<String, Object>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.w(
      _formatMessage(message, operation: operation, context: context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String? operation,
    Map<String, Object>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      _formatMessage(message, operation: operation, context: context),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _formatMessage(
    String message, {
    String? operation,
    Map<String, Object>? context,
  }) {
    final buffer = StringBuffer();

    if (operation != null) {
      buffer.write('[$operation] ');
    }

    buffer.write(message);

    if (context != null && context.isNotEmpty) {
      buffer.write(' | context: $context');
    }

    return buffer.toString();
  }
}

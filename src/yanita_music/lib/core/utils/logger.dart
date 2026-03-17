import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// Logger centralizado para el proyecto.
/// Filtra por nivel y registra con timestamps.
class AppLogger {
  AppLogger._();

  static LogLevel _currentLevel = LogLevel.debug;

  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  static void debug(String message, {String tag = 'APP'}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  static void info(String message, {String tag = 'APP'}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String tag = 'APP'}) {
    _log(LogLevel.warning, message, tag: tag);
  }

  static void error(
    String message, {
    String tag = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag);
    if (error != null) {
      developer.log(
        'Error detail: $error',
        name: tag,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _log(LogLevel level, String message, {required String tag}) {
    if (level.index < _currentLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = level.name.toUpperCase();
    final formatted = '[$prefix] $timestamp | $message';

    developer.log(formatted, name: tag);
  }
}

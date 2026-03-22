import 'package:logger/logger.dart' as log_pkg;
import 'package:yanita_music/domain/entities/log_entry.dart';
import 'package:yanita_music/domain/repositories/log_repository.dart';
import 'package:get_it/get_it.dart';

/// Logger global de la aplicación que guarda registros en la base de datos.
/// Reemplaza la implementación anterior basada solo en developer.log.
class AppLogger {
  AppLogger._();

  static final log_pkg.Logger _logger = log_pkg.Logger(
    printer: log_pkg.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: log_pkg.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static LogRepository? _repository;
  static bool _isPersisting = false;

  static void _ensureRepository() {
    if (_repository == null && GetIt.I.isRegistered<LogRepository>()) {
      _repository = GetIt.I<LogRepository>();
    }
  }

  static void info(String message, {String tag = 'APP', dynamic error, StackTrace? stackTrace}) {
    _logger.i('[$tag] $message', error: error, stackTrace: stackTrace);
    _persist(LogLevel.info, message, tag, stackTrace);
  }

  static void warning(String message, {String tag = 'APP', dynamic error, StackTrace? stackTrace}) {
    _logger.w('[$tag] $message', error: error, stackTrace: stackTrace);
    _persist(LogLevel.warning, message, tag, stackTrace);
  }

  static void error(
    String message, {
    String tag = 'APP',
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e('[$tag] $message', error: error, stackTrace: stackTrace);
    _persist(LogLevel.error, message, tag, stackTrace);
  }

  static void debug(String message, {String tag = 'APP'}) {
    _logger.d('[$tag] $message');
    _persist(LogLevel.debug, message, tag, null);
  }

  static void _persist(LogLevel level, String message, String tag, StackTrace? stackTrace) {
    if (_isPersisting) return; // Evitar recursión infinita si el repo intenta loguear
    
    _isPersisting = true;
    try {
      _ensureRepository();
      if (_repository != null) {
        final log = LogEntry(
          level: level,
          message: message,
          tag: tag,
          stackTrace: stackTrace?.toString(),
          createdAt: DateTime.now(),
        );
        _repository!.saveLog(log);
      }
    } finally {
      _isPersisting = false;
    }
  }
}

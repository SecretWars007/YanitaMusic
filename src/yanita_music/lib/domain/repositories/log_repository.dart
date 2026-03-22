import 'package:yanita_music/domain/entities/log_entry.dart';

abstract class LogRepository {
  Future<void> saveLog(LogEntry log);
  Future<List<LogEntry>> getLogs({int limit = 100, int offset = 0, LogLevel? minLevel});
  Future<void> clearLogs();
  Future<void> deleteOldLogs(Duration age);
}

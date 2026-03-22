import 'package:flutter/foundation.dart';
import 'package:yanita_music/data/datasources/local/database_helper.dart';
import 'package:yanita_music/domain/entities/log_entry.dart';
import 'package:yanita_music/domain/repositories/log_repository.dart';
import 'package:yanita_music/core/constants/db_constants.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: LogRepository)
class LogRepositoryImpl implements LogRepository {
  final DatabaseHelper _dbHelper;

  LogRepositoryImpl(this._dbHelper);

  @override
  Future<void> saveLog(LogEntry log) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(DbConstants.logsTable, log.toMap());
    } catch (e) {
      // Silenciosamente fallar para evitar bucles infinitos de log
      debugPrint('Error guardando log en DB: $e');
    }
  }

  @override
  Future<List<LogEntry>> getLogs({int limit = 100, int offset = 0, LogLevel? minLevel}) async {
    final db = await _dbHelper.database;
    
    String? where;
    List<dynamic>? whereArgs;
    
    if (minLevel != null) {
      // Simplificación: solo filtrar por el nivel exacto o implementar lógica de jerarquía si es necesario
      where = '${DbConstants.colLogLevel} = ?';
      whereArgs = [minLevel.name];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.logsTable,
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: '${DbConstants.colLogCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) => LogEntry.fromMap(maps[i]));
  }

  @override
  Future<void> clearLogs() async {
    final db = await _dbHelper.database;
    await db.delete(DbConstants.logsTable);
  }

  @override
  Future<void> deleteOldLogs(Duration age) async {
    final db = await _dbHelper.database;
    final cutoff = DateTime.now().subtract(age).toIso8601String();
    
    await db.delete(
      DbConstants.logsTable,
      where: '${DbConstants.colLogCreatedAt} < ?',
      whereArgs: [cutoff],
    );
  }
}

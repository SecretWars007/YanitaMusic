import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:yanita_music/core/constants/app_constants.dart';
import 'package:yanita_music/core/error/exceptions.dart' as app_exc;
import 'package:yanita_music/core/utils/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

/// Helper singleton para gestión de la base de datos SQLite.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _tag = 'DatabaseHelper';

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inicializar FFI solo en plataformas de escritorio para evitar MissingPluginException en móviles
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, AppConstants.dbName);

    // Verificar existencia usando File de dart:io (más seguro que databaseExists)
    final exists = File(path).existsSync();

    if (!exists) {
      AppLogger.info(
        'Copiando base de datos preempaquetada desde assets...',
        tag: _tag,
      );
      try {
        // Crear el directorio si no existe
        await Directory(dirname(path)).create(recursive: true);

        // Copiar desde assets
        final ByteData data = await rootBundle.load(
          join('assets', 'database', AppConstants.dbName),
        );
        final List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Escribir el archivo
        await File(path).writeAsBytes(bytes, flush: true);
        AppLogger.info(
          'Base de datos copiada exitosamente a: $path',
          tag: _tag,
        );
      } catch (e) {
        AppLogger.error(
          'Error al copiar la base de datos desde assets: $e',
          tag: _tag,
        );
        throw const app_exc.DatabaseException(
          'No se pudo inicializar la base de datos preempaquetada',
        );
      }
    } else {
      AppLogger.info('Base de datos ya existe en: $path', tag: _tag);
    }

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.rawQuery('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA foreign_keys=ON');
    await db.execute('PRAGMA synchronous=NORMAL');
    await db.execute('PRAGMA cache_size=10000');
    await db.execute('PRAGMA temp_store=MEMORY');
  }

  // --- MÉTODOS DE LOGS ---

  Future<int> insertLog(Map<String, dynamic> logData) async {
    try {
      final db = await database;
      return await db.insert('app_logs', logData);
    } catch (e) {
      // ignore: avoid_print
      print('CRITICAL ERROR: Failed to persist log to DB: $e');
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getLogs({int limit = 100}) async {
    final db = await database;
    return await db.query('app_logs', orderBy: 'timestamp DESC', limit: limit);
  }

  Future<void> clearLogs() async {
    final db = await database;
    await db.delete('app_logs');
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

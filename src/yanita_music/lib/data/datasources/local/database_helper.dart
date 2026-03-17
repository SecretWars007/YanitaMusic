import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yanita_music/core/constants/app_constants.dart';
import 'package:yanita_music/core/constants/db_constants.dart';
import 'package:logger/logger.dart';

/// Helper singleton para gestión de la base de datos SQLite.
///
/// Implementa:
/// - Patrón singleton para conexión única
/// - Migraciones versionadas
/// - WAL mode para mejor rendimiento
/// - Creación de índices para queries frecuentes
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final Logger _logger = Logger();

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    _logger.i('Inicializando base de datos en: $path');

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configura la conexión con opciones de seguridad y rendimiento.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA foreign_keys=ON');
    await db.execute('PRAGMA synchronous=NORMAL');
    await db.execute('PRAGMA cache_size=10000');
    await db.execute('PRAGMA temp_store=MEMORY');
  }

  /// Crea el esquema inicial de la base de datos.
  Future<void> _onCreate(Database db, int version) async {
    _logger.i('Creando esquema de base de datos v$version');

    // Tabla de partituras
    await db.execute('''
      CREATE TABLE ${DbConstants.scoresTable} (
        ${DbConstants.colId} TEXT PRIMARY KEY NOT NULL,
        ${DbConstants.colTitle} TEXT NOT NULL,
        ${DbConstants.colAudioPath} TEXT NOT NULL,
        ${DbConstants.colNoteEvents} TEXT NOT NULL DEFAULT '[]',
        ${DbConstants.colMidiData} TEXT,
        ${DbConstants.colMusicXml} TEXT,
        ${DbConstants.colDuration} REAL NOT NULL DEFAULT 0.0,
        ${DbConstants.colTempo} REAL,
        ${DbConstants.colChecksum} TEXT,
        ${DbConstants.colCreatedAt} TEXT NOT NULL,
        ${DbConstants.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    // Tabla del cancionero
    await db.execute('''
      CREATE TABLE ${DbConstants.songbookTable} (
        ${DbConstants.colSongId} TEXT PRIMARY KEY NOT NULL,
        ${DbConstants.colSongTitle} TEXT NOT NULL,
        ${DbConstants.colArtist} TEXT,
        ${DbConstants.colScoreId} TEXT NOT NULL,
        ${DbConstants.colCategory} TEXT,
        ${DbConstants.colDifficulty} INTEGER NOT NULL DEFAULT 3,
        ${DbConstants.colIsFavorite} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colSongCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colScoreId})
          REFERENCES ${DbConstants.scoresTable} (${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    // Tabla de métricas
    await db.execute('''
      CREATE TABLE ${DbConstants.metricsTable} (
        ${DbConstants.colMetricId} TEXT PRIMARY KEY NOT NULL,
        ${DbConstants.colMetricScoreId} TEXT NOT NULL,
        ${DbConstants.colPrecision} REAL NOT NULL,
        ${DbConstants.colRecall} REAL NOT NULL,
        ${DbConstants.colFMeasure} REAL NOT NULL,
        ${DbConstants.colIsPolyphonic} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colMetricCreatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colMetricScoreId})
          REFERENCES ${DbConstants.scoresTable} (${DbConstants.colId})
          ON DELETE CASCADE
      )
    ''');

    // Índices para optimizar queries frecuentes
    await db.execute('''
      CREATE INDEX idx_scores_created_at 
      ON ${DbConstants.scoresTable} (${DbConstants.colCreatedAt} DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_songbook_score_id 
      ON ${DbConstants.songbookTable} (${DbConstants.colScoreId})
    ''');
    await db.execute('''
      CREATE INDEX idx_songbook_category 
      ON ${DbConstants.songbookTable} (${DbConstants.colCategory})
    ''');
    await db.execute('''
      CREATE INDEX idx_songbook_favorite 
      ON ${DbConstants.songbookTable} (${DbConstants.colIsFavorite})
    ''');
    await db.execute('''
      CREATE INDEX idx_metrics_score_id 
      ON ${DbConstants.metricsTable} (${DbConstants.colMetricScoreId})
    ''');

    _logger.i('Esquema de base de datos creado correctamente');
  }

  /// Maneja migraciones de esquema entre versiones.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Migrando base de datos de v$oldVersion a v$newVersion');
    // Futuras migraciones aquí
  }

  /// Cierra la conexión a la base de datos.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

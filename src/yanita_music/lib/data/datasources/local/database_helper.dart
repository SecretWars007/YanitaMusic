import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:yanita_music/core/constants/app_constants.dart';
import 'package:yanita_music/core/constants/db_constants.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';


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
    // Usamos rawQuery para PRAGMAs que pueden retornar resultados para evitar errores de tipo "SQLITE_OK"
    await db.rawQuery('PRAGMA journal_mode=WAL');
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
        ${DbConstants.colSpectrogramData} TEXT,
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
    
    // Insertar datos de prueba iniciales
    await _seedData(db);
  }

  /// Inserta datos de prueba requeridos por el usuario (Himno a la Alegría).
  Future<void> _seedData(Database db) async {
    _logger.i('Sembrando datos de prueba iniciales...');
    
    final scoreId = const Uuid().v4();
    final songId = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    const odeToJoyXml = '''<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
  <work><work-title>Himno a la Alegría</work-title></work>
  <part-list>
    <score-part id="P1"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes>
        <divisions>1</divisions>
        <key><fifths>0</fifths></key>
        <time><beats>4</beats><beat-type>4</beat-type></time>
        <clef><sign>G</sign><line>2</line></clef>
      </attributes>
      <direction><sound tempo="120"/></direction>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>F</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>G</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
    </measure>
    <measure number="2">
      <note><pitch><step>G</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>F</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>E</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
      <note><pitch><step>D</step><octave>4</octave></pitch><duration>1</duration><type>quarter</type></note>
    </measure>
  </part>
</score-partwise>''';

    // Insertar Score
    await db.insert(DbConstants.scoresTable, {
      DbConstants.colId: scoreId,
      DbConstants.colTitle: 'Himno a la Alegría (Demo)',
      DbConstants.colAudioPath: 'assets/audio/ode_to_joy.mp3',
      DbConstants.colNoteEvents: '[]', // Se cargará desde MusicXML
      DbConstants.colMusicXml: odeToJoyXml,
      DbConstants.colDuration: 4.0,
      DbConstants.colTempo: 120.0,
      DbConstants.colCreatedAt: now,
      DbConstants.colUpdatedAt: now,
    });

    // Insertar en Cancionero
    await db.insert(DbConstants.songbookTable, {
      DbConstants.colSongId: songId,
      DbConstants.colSongTitle: 'Himno a la Alegría',
      DbConstants.colArtist: 'Ludwig van Beethoven',
      DbConstants.colScoreId: scoreId,
      DbConstants.colCategory: 'Clásica',
      DbConstants.colDifficulty: 2,
      DbConstants.colIsFavorite: 1,
      DbConstants.colSongCreatedAt: now,
    });

    _logger.i('Datos de prueba sembrados exitosamente.');
  }


  /// Maneja migraciones de esquema entre versiones.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i('Migrando base de datos de v$oldVersion a v$newVersion');

    if (oldVersion < 2) {
      // v2: Agregar columna de espectrograma a tabla de partituras
      await db.execute('''
        ALTER TABLE ${DbConstants.scoresTable}
        ADD COLUMN ${DbConstants.colSpectrogramData} TEXT
      ''');
      _logger.i('Migración v2: columna spectrogram_data agregada');
    }
  }

  /// Cierra la conexión a la base de datos.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

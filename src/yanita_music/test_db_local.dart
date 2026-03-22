import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'lib/core/constants/db_constants.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

Future<void> main() async {
  // Inicializamos FFI para poder crear y consultar SQLite localmente en Windows
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;

  // Archivo de base de datos en el directorio del proyecto
  const dbPath = 'piano_scribe_local.db';
  if (File(dbPath).existsSync()) {
    File(dbPath).deleteSync();
  }

  // ignore: avoid_print
  print('========================================');
  // ignore: avoid_print
  print('Creando base de datos en: $dbPath');
  final db = await databaseFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${DbConstants.scoresTable} (
            ${DbConstants.colId} TEXT PRIMARY KEY NOT NULL,
            ${DbConstants.colTitle} TEXT NOT NULL,
            ${DbConstants.colAudioPath} TEXT NOT NULL,
            ${DbConstants.colNoteEvents} TEXT NOT NULL DEFAULT '[]',
            ${DbConstants.colMidiData} TEXT,
            ${DbConstants.colCreatedAt} TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE ${DbConstants.songsTable} (
            ${DbConstants.colId} TEXT PRIMARY KEY NOT NULL,
            ${DbConstants.colTitle} TEXT NOT NULL,
            ${DbConstants.colArtist} TEXT,
            ${DbConstants.colAudioPath} TEXT NOT NULL,
            ${DbConstants.colScorePath} TEXT,
            ${DbConstants.colCoverPath} TEXT,
            ${DbConstants.colIsDemo} INTEGER DEFAULT 0,
            ${DbConstants.colDifficulty} TEXT,
            ${DbConstants.colDuration} INTEGER,
            ${DbConstants.colCreatedAt} TEXT NOT NULL
          )
        ''');
      },
    ),
  );

  // ignore: avoid_print
  print('✓ Base de datos y tablas creadas exitosamente.');
  // ignore: avoid_print
  print('Insertando registros demo...');

  final now = DateTime.now().toIso8601String();
  const uuid = Uuid();

  final demoSongs = [
    {
      DbConstants.colId: uuid.v4(),
      DbConstants.colTitle: 'Bach: Minuet in G',
      DbConstants.colArtist: 'J.S. Bach',
      DbConstants.colAudioPath: 'assets/audio/bach_minuet_g.mp3',
      DbConstants.colScorePath: 'assets/scores/bach_minuet_g.mxl',
      DbConstants.colCoverPath: 'assets/images/placeholder.jpg',
      DbConstants.colIsDemo: 1,
      DbConstants.colDifficulty: 'Fácil',
      DbConstants.colDuration: 132,
      DbConstants.colCreatedAt: now,
    },
    {
      DbConstants.colId: uuid.v4(),
      DbConstants.colTitle: 'Beethoven: 5th Symphony',
      DbConstants.colArtist: 'L. van Beethoven',
      DbConstants.colAudioPath: 'assets/audio/beethoven_5th_symphony.mp3',
      DbConstants.colScorePath: 'assets/scores/beethoven_5th_symphony.mxl',
      DbConstants.colCoverPath: 'assets/images/placeholder.jpg',
      DbConstants.colIsDemo: 1,
      DbConstants.colDifficulty: 'Avanzado',
      DbConstants.colDuration: 120,
      DbConstants.colCreatedAt: now,
    },
    {
      DbConstants.colId: uuid.v4(),
      DbConstants.colTitle: 'Bella Ciao',
      DbConstants.colArtist: 'Traditional',
      DbConstants.colAudioPath: 'assets/audio/bella_ciao.mp3',
      DbConstants.colScorePath: 'assets/scores/bella_ciao.mxl',
      DbConstants.colCoverPath: 'assets/images/placeholder.jpg',
      DbConstants.colIsDemo: 1,
      DbConstants.colDifficulty: 'Intermedio',
      DbConstants.colDuration: 120,
      DbConstants.colCreatedAt: now,
    },
  ];

  for (var song in demoSongs) {
    await db.insert(DbConstants.songsTable, song);

    final scoreEntry = {
      DbConstants.colId: song[DbConstants.colId],
      DbConstants.colTitle: song[DbConstants.colTitle],
      DbConstants.colAudioPath: song[DbConstants.colAudioPath],
      DbConstants.colNoteEvents: '[]',
      DbConstants.colMidiData: null,
      DbConstants.colCreatedAt: song[DbConstants.colCreatedAt],
    };
    await db.insert(DbConstants.scoresTable, scoreEntry);
  }

  // ignore: avoid_print
  print('✓ Registros insertados.\\n');
  // ignore: avoid_print
  print('========================================');
  // ignore: avoid_print
  print('EJECUTANDO SELECT PARA VALIDAR REGISTROS');
  // ignore: avoid_print
  print('========================================\\n');

  // ignore: avoid_print
  print(
    ">> SELECT * FROM ${DbConstants.scoresTable} WHERE ${DbConstants.colNoteEvents} = '[]'",
  );
  final resultScores = await db.rawQuery(
    "SELECT * FROM ${DbConstants.scoresTable} WHERE ${DbConstants.colNoteEvents} = '[]'",
  );

  // ignore: avoid_print
  print('Resultados (${resultScores.length} partituras):');
  for (var row in resultScores) {
    // ignore: avoid_print
    print(' - ID: ${row[DbConstants.colId]}');
    // ignore: avoid_print
    print('   Título: ${row[DbConstants.colTitle]}');
    // ignore: avoid_print
    print('   Audio: ${row[DbConstants.colAudioPath]}');
    // ignore: avoid_print
    print('   -----------------------------------');
  }

  await db.close();
  // ignore: avoid_print
  print('========================================');
}

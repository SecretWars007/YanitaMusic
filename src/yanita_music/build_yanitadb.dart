import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:uuid/uuid.dart';

// --- COPIA DE UTILIDADES INTEGRADAS PARA EVITAR DEPENDENCIAS FLUTTER ---
class NoteEvent {
  final int midiNote;
  final double startTime;
  final double endTime;
  final int velocity;

  const NoteEvent({
    required this.midiNote,
    required this.startTime,
    required this.endTime,
    required this.velocity,
  });

  Map<String, dynamic> toJson() => {
    'start_time': startTime,
    'end_time': endTime,
    'midi_note': midiNote,
    'velocity': velocity,
    'confidence': 1.0,
  };
}

class MusicXmlParserLocal {
  List<NoteEvent> parse(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final notes = <NoteEvent>[];
      final measures = document.findAllElements('measure');
      double currentTime = 0.0;
      int divisions = 1;
      int tempo = 120;

      for (var measure in measures) {
        final attr = measure.getElement('attributes');
        if (attr != null) {
          final divsNode = attr.getElement('divisions');
          if (divsNode != null) {
            divisions = int.tryParse(divsNode.innerText) ?? divisions;
          }
        }

        final soundTags = measure.findAllElements('sound');
        for (var sound in soundTags) {
          final tAttr = sound.getAttribute('tempo');
          if (tAttr != null) tempo = double.tryParse(tAttr)?.round() ?? tempo;
        }

        final noteElements = measure.children.whereType<XmlElement>().where(
          (e) => e.name.local == 'note',
        );

        for (var noteNode in noteElements) {
          final isRest = noteNode.getElement('rest') != null;
          final durationNode = noteNode.getElement('duration');
          if (durationNode == null) continue;

          final durationDivs = int.tryParse(durationNode.innerText) ?? 1;
          final durationSeconds = (durationDivs / divisions) * (60.0 / tempo);

          if (!isRest) {
            final pitchNode = noteNode.getElement('pitch');
            if (pitchNode != null) {
              final step = pitchNode.getElement('step')?.innerText ?? 'C';
              final octave =
                  int.tryParse(
                    pitchNode.getElement('octave')?.innerText ?? '4',
                  ) ??
                  4;
              final alter =
                  int.tryParse(
                    pitchNode.getElement('alter')?.innerText ?? '0',
                  ) ??
                  0;
              final midiPitch = _pitchToMidi(step, octave, alter);

              final isChord = noteNode.getElement('chord') != null;
              final startTime = isChord && notes.isNotEmpty
                  ? notes.last.startTime
                  : currentTime;
              final endTime = startTime + durationSeconds;

              notes.add(
                NoteEvent(
                  midiNote: midiPitch,
                  startTime: startTime,
                  endTime: endTime,
                  velocity: 80,
                ),
              );

              if (!isChord) currentTime += durationSeconds;
            }
          } else {
            currentTime += durationSeconds;
          }
        }
      }
      return notes;
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing MusicXML: $e');
      return [];
    }
  }

  int _pitchToMidi(String step, int octave, int alter) {
    const stepToOffset = {
      'C': 0,
      'D': 2,
      'E': 4,
      'F': 5,
      'G': 7,
      'A': 9,
      'B': 11,
    };
    return (octave + 1) * 12 + (stepToOffset[step] ?? 0) + alter;
  }
}

Future<void> main() async {
  // ignore: avoid_print
  print('===== GENERADOR DE YANITADB (SOPORTE COMPLETO) =====');
  
  final parser = MusicXmlParserLocal();
  const uuid = Uuid();
  final now = DateTime.now().toIso8601String();

  final demoSongsConfig = [
    {
      'title': 'Bach: Minuet in G',
      'artist': 'J.S. Bach',
      'audioPath': 'assets/audio/bach_minuet_g.mp3',
      'scorePath': 'assets/scores/bach_minuet_g.mxl',
      'coverPath': 'assets/images/placeholder.jpg',
      'difficulty': 1,
      'duration': 132.0,
    },
    {
      'title': 'Beethoven: 5th Symphony',
      'artist': 'L. van Beethoven',
      'audioPath': 'assets/audio/beethoven_5th_symphony.mp3',
      'scorePath': 'assets/scores/beethoven_5th_symphony.mxl',
      'coverPath': 'assets/images/placeholder.jpg',
      'difficulty': 5,
      'duration': 120.0,
    },
    {
      'title': 'Bella Ciao',
      'artist': 'Traditional',
      'audioPath': 'assets/audio/bella_ciao.mp3',
      'scorePath': 'assets/scores/bella_ciao.mxl',
      'coverPath': 'assets/images/placeholder.jpg',
      'difficulty': 3,
      'duration': 120.0,
    },
  ];

  final sb = StringBuffer();

  // Create tables precisely as defined in DbConstants and Models
  sb.writeln('''
DROP TABLE IF EXISTS scores;
DROP TABLE IF EXISTS songs;
DROP TABLE IF EXISTS metrics;
DROP TABLE IF EXISTS app_logs;

CREATE TABLE scores (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL,
  audio_path TEXT NOT NULL,
  midi_data TEXT,
  music_xml TEXT,
  note_events TEXT NOT NULL DEFAULT '[]',
  duration REAL,
  tempo REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  checksum TEXT,
  spectrogram_data TEXT
);

CREATE TABLE songs (
  id TEXT PRIMARY KEY NOT NULL,
  song_title TEXT NOT NULL,
  artist TEXT,
  score_id TEXT NOT NULL,
  category TEXT,
  difficulty INTEGER,
  is_favorite INTEGER DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE metrics (
  id TEXT PRIMARY KEY NOT NULL,
  score_id TEXT NOT NULL,
  precision_val REAL,
  recall_val REAL,
  f_measure REAL,
  is_polyphonic INTEGER,
  created_at TEXT NOT NULL
);

CREATE TABLE app_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  level TEXT NOT NULL,
  message TEXT NOT NULL,
  tag TEXT,
  stack_trace TEXT,
  created_at TEXT NOT NULL
);
''');

  for (var song in demoSongsConfig) {
    // ignore: avoid_print
    print('Processing: ${song['title']}...');
    final scorePath = song['scorePath'] as String;
    final file = File(scorePath);
    
    String eventsJson = '[]';
    
    if (file.existsSync()) {
      try {
        final bytes = file.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        String xmlContent = '';
        
        for (final archiveFile in archive) {
          if (archiveFile.isFile &&
              archiveFile.name.endsWith('.xml') &&
              !archiveFile.name.contains('META-INF')) {
            xmlContent = utf8.decode(archiveFile.content as List<int>);
            break;
          }
        }
        
        if (xmlContent.isNotEmpty) {
          final notes = parser.parse(xmlContent);
          final notesMapList = notes.map((e) => e.toJson()).toList();
          eventsJson = jsonEncode(notesMapList);
          // ignore: avoid_print
          print(' -> ${notes.length} NoteEvents extraídos exitosamente!');
        } else {
          // ignore: avoid_print
          print(' -> ADVERTENCIA: No se encontró archivo XML dentro de $scorePath');
        }
      } catch (e) {
        // ignore: avoid_print
        print(' -> ERROR extrayendo $scorePath: $e');
      }
    } else {
      // ignore: avoid_print
      print(' -> ADVERTENCIA: El archivo $scorePath no existe. Insertando array vacío.');
    }

    final scoreId = uuid.v4();
    final songId = uuid.v4();
    final title = song['title'] as String;
    final artist = song['artist'] as String;
    final audioPath = song['audioPath'] as String;
    final difficulty = song['difficulty'] as int;
    final duration = song['duration'] as double;

    // Escapar comillas simples
    final escapedEventsJson = eventsJson.replaceAll("'", "''");
    final escapedTitle = title.replaceAll("'", "''");
    final escapedArtist = artist.replaceAll("'", "''");

    // INSERT INTO scores
    sb.writeln('''
INSERT INTO scores (id, title, audio_path, midi_data, music_xml, note_events, duration, tempo, created_at, updated_at, checksum, spectrogram_data) 
VALUES ('$scoreId', '$escapedTitle', '$audioPath', NULL, NULL, '$escapedEventsJson', $duration, 120.0, '$now', '$now', NULL, NULL);
''');

    // INSERT INTO songs
    sb.writeln('''
INSERT INTO songs (id, song_title, artist, score_id, category, difficulty, is_favorite, created_at) 
VALUES ('$songId', '$escapedTitle', '$escapedArtist', '$scoreId', 'Clásica', $difficulty, 0, '$now');
''');

  }

  // Escribir SQL a disco
  final sqlFile = File('seed_yanitadb.sql');
  sqlFile.writeAsStringSync(sb.toString());
  // ignore: avoid_print
  print('========================================');
  // ignore: avoid_print
  print('Script SQL generado: seed_yanitadb.sql');
}

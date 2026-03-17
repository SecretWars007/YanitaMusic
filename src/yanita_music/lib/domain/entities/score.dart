import 'package:equatable/equatable.dart';
import 'package:yanita_music/domain/entities/note_event.dart';

/// Entidad que representa una partitura musical completa.
///
/// Contiene los eventos de nota transcritos, metadatos y
/// representaciones en formatos exportables (MIDI, MusicXML).
class Score extends Equatable {
  final String id;
  final String title;
  final String audioPath;
  final List<NoteEvent> noteEvents;
  final double duration;
  final double? tempo;
  final String? midiData;
  final String? musicXml;
  final String? checksum;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Score({
    required this.id,
    required this.title,
    required this.audioPath,
    required this.noteEvents,
    required this.duration,
    this.tempo,
    this.midiData,
    this.musicXml,
    this.checksum,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Número total de notas detectadas.
  int get noteCount => noteEvents.length;

  /// Verifica si la pieza es polifónica (notas simultáneas).
  bool get isPolyphonic {
    for (var i = 0; i < noteEvents.length - 1; i++) {
      for (var j = i + 1; j < noteEvents.length; j++) {
        if (noteEvents[j].startTime < noteEvents[i].endTime &&
            noteEvents[j].startTime >= noteEvents[i].startTime) {
          return true;
        }
      }
    }
    return false;
  }

  Score copyWith({
    String? id,
    String? title,
    String? audioPath,
    List<NoteEvent>? noteEvents,
    double? duration,
    double? tempo,
    String? midiData,
    String? musicXml,
    String? checksum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Score(
      id: id ?? this.id,
      title: title ?? this.title,
      audioPath: audioPath ?? this.audioPath,
      noteEvents: noteEvents ?? this.noteEvents,
      duration: duration ?? this.duration,
      tempo: tempo ?? this.tempo,
      midiData: midiData ?? this.midiData,
      musicXml: musicXml ?? this.musicXml,
      checksum: checksum ?? this.checksum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, audioPath, noteCount, duration];
}

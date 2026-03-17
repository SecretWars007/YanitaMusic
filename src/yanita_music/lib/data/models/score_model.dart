import 'package:yanita_music/data/models/note_event_model.dart';
import 'package:yanita_music/domain/entities/score.dart';

/// Modelo de datos para Score con serialización SQLite.
class ScoreModel extends Score {
  const ScoreModel({
    required super.id,
    required super.title,
    required super.audioPath,
    required super.noteEvents,
    required super.duration,
    super.tempo,
    super.midiData,
    super.musicXml,
    super.checksum,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ScoreModel.fromMap(Map<String, dynamic> map) {
    final noteEventsJson = map['note_events'] as String? ?? '[]';
    final noteEvents = NoteEventModel.listFromJson(noteEventsJson);

    return ScoreModel(
      id: map['id'] as String,
      title: map['title'] as String,
      audioPath: map['audio_path'] as String,
      noteEvents: noteEvents,
      duration: (map['duration'] as num).toDouble(),
      tempo: (map['tempo'] as num?)?.toDouble(),
      midiData: map['midi_data'] as String?,
      musicXml: map['music_xml'] as String?,
      checksum: map['checksum'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    final noteEventModels = noteEvents
        .map((e) => NoteEventModel.fromEntity(e))
        .toList();

    return {
      'id': id,
      'title': title,
      'audio_path': audioPath,
      'note_events': NoteEventModel.listToJson(noteEventModels),
      'duration': duration,
      'tempo': tempo,
      'midi_data': midiData,
      'music_xml': musicXml,
      'checksum': checksum,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ScoreModel.fromEntity(Score entity) {
    return ScoreModel(
      id: entity.id,
      title: entity.title,
      audioPath: entity.audioPath,
      noteEvents: entity.noteEvents,
      duration: entity.duration,
      tempo: entity.tempo,
      midiData: entity.midiData,
      musicXml: entity.musicXml,
      checksum: entity.checksum,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

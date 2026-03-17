import 'dart:convert';
import 'package:yanita_music/domain/entities/note_event.dart';

/// Modelo de datos para NoteEvent con serialización JSON.
///
/// Extiende la entidad del dominio agregando capacidades
/// de serialización/deserialización para persistencia en SQLite.
class NoteEventModel extends NoteEvent {
  const NoteEventModel({
    required super.startTime,
    required super.endTime,
    required super.midiNote,
    required super.velocity,
    super.confidence,
  });

  /// Crea modelo desde un Map (lectura de DB/JSON).
  factory NoteEventModel.fromMap(Map<String, dynamic> map) {
    return NoteEventModel(
      startTime: (map['start_time'] as num).toDouble(),
      endTime: (map['end_time'] as num).toDouble(),
      midiNote: map['midi_note'] as int,
      velocity: map['velocity'] as int,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convierte a Map para almacenamiento.
  Map<String, dynamic> toMap() {
    return {
      'start_time': startTime,
      'end_time': endTime,
      'midi_note': midiNote,
      'velocity': velocity,
      'confidence': confidence,
    };
  }

  /// Crea modelo desde la entidad de dominio.
  factory NoteEventModel.fromEntity(NoteEvent entity) {
    return NoteEventModel(
      startTime: entity.startTime,
      endTime: entity.endTime,
      midiNote: entity.midiNote,
      velocity: entity.velocity,
      confidence: entity.confidence,
    );
  }

  /// Serializa una lista de NoteEventModel a JSON string.
  static String listToJson(List<NoteEventModel> events) {
    return jsonEncode(events.map((e) => e.toMap()).toList());
  }

  /// Deserializa una lista de NoteEventModel desde JSON string.
  static List<NoteEventModel> listFromJson(String jsonStr) {
    final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
    return decoded
        .map((e) => NoteEventModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

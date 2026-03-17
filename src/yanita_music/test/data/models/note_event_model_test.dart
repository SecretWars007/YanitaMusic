import 'package:flutter_test/flutter_test.dart';
import 'package:yanita_music/data/models/note_event_model.dart';

void main() {
  group('NoteEventModel', () {
    final testMap = {
      'start_time': 1.5,
      'end_time': 2.0,
      'midi_note': 60,
      'velocity': 80,
      'confidence': 0.95,
    };

    test('fromMap creates correct instance', () {
      final model = NoteEventModel.fromMap(testMap);
      expect(model.startTime, equals(1.5));
      expect(model.endTime, equals(2.0));
      expect(model.midiNote, equals(60));
      expect(model.velocity, equals(80));
      expect(model.confidence, equals(0.95));
    });

    test('toMap serializes correctly', () {
      final model = NoteEventModel.fromMap(testMap);
      final map = model.toMap();
      expect(map['start_time'], equals(1.5));
      expect(map['midi_note'], equals(60));
    });

    test('fromMap handles missing confidence', () {
      final mapWithoutConfidence = {
        'start_time': 1.0,
        'end_time': 1.5,
        'midi_note': 48,
        'velocity': 64,
      };
      final model = NoteEventModel.fromMap(mapWithoutConfidence);
      expect(model.confidence, equals(1.0));
    });

    test('listToJson and listFromJson roundtrip', () {
      final models = [
        NoteEventModel.fromMap(testMap),
        NoteEventModel.fromMap({
          'start_time': 3.0,
          'end_time': 3.5,
          'midi_note': 72,
          'velocity': 100,
          'confidence': 0.8,
        }),
      ];

      final json = NoteEventModel.listToJson(models);
      final restored = NoteEventModel.listFromJson(json);

      expect(restored.length, equals(2));
      expect(restored[0].midiNote, equals(60));
      expect(restored[1].midiNote, equals(72));
    });

    test('noteName returns correct scientific notation', () {
      final model = NoteEventModel.fromMap(testMap); // midiNote = 60 = C4
      expect(model.noteName, equals('C4'));
    });

    test('midiPitch alias returns midiNote', () {
      final model = NoteEventModel.fromMap(testMap);
      expect(model.midiPitch, equals(model.midiNote));
    });
  });
}

import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/domain/entities/note_event.dart';

/// Utility class to generate demo scores for testing and onboarding.
class DemoScoreGenerator {
  DemoScoreGenerator._();

  /// Generates the "Ode to Joy" (Himno a la Alegría) melody.
  ///
  /// Uses MIDI pitch numbers:
  /// E4=64, F4=65, G4=67, D4=62, C4=60
  static Score generateOdeToJoy() {
    final now = DateTime.now();
    final notes = <NoteEvent>[
      // Bar 1: E E F G
      _note(0.0, 0.5, 64),
      _note(0.5, 1.0, 64),
      _note(1.0, 1.5, 65),
      _note(1.5, 2.0, 67),
      
      // Bar 2: G F E D
      _note(2.0, 2.5, 67),
      _note(2.5, 3.0, 65),
      _note(3.0, 3.5, 64),
      _note(3.5, 4.0, 62),
      
      // Bar 3: C C D E
      _note(4.0, 4.5, 60),
      _note(4.5, 5.0, 60),
      _note(5.0, 5.5, 62),
      _note(5.5, 6.0, 64),
      
      // Bar 4: E. D D
      _note(6.0, 6.75, 64),
      _note(6.75, 7.0, 62),
      _note(7.0, 8.0, 62),
      
      // Bar 5: E E F G
      _note(8.0, 8.5, 64),
      _note(8.5, 9.0, 64),
      _note(9.0, 9.5, 65),
      _note(9.5, 10.0, 67),
      
      // Bar 6: G F E D
      _note(10.0, 10.5, 67),
      _note(10.5, 11.0, 65),
      _note(11.0, 11.5, 64),
      _note(11.5, 12.0, 62),
      
      // Bar 7: C C D E
      _note(12.0, 12.5, 60),
      _note(12.5, 13.0, 60),
      _note(13.0, 13.5, 62),
      _note(13.5, 14.0, 64),
      
      // Bar 8: D. C C
      _note(14.0, 14.75, 62),
      _note(14.75, 15.0, 60),
      _note(15.0, 16.0, 60),
    ];

    // Llenar 64 segundos repitiendo el bloque de 16 segundos 4 veces
    final List<NoteEvent> extendedNotes = <NoteEvent>[];
    for (int i = 0; i < 4; i++) {
      final double offset = i * 16.0;
      for (final note in notes) {
        extendedNotes.add(
          NoteEvent(
            startTime: note.startTime + offset,
            endTime: note.endTime + offset,
            midiNote: note.midiNote,
            velocity: note.velocity,
          ),
        );
      }
    }

    return Score(
      id: 'demo-ode-to-joy',
      title: 'HIMNO A LA ALEGRÍA (Demo)',
      audioPath: 'assets/audio/ode_to_joy.mp3',
      noteEvents: extendedNotes,
      duration: 64.0, // Cambiado de 16 a 64
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Genera la melodía de "Busca lo más vital" (The Bare Necessities).
  static Score generateTheBareNecessities() {
    final now = DateTime.now();
    final notes = <NoteEvent>[
      // Frase 1: F G A F
      _note(0.0, 0.5, 65),
      _note(0.5, 1.0, 67),
      _note(1.0, 1.5, 69),
      _note(1.5, 2.0, 65),
      
      // Frase 2: G A F
      _note(2.5, 3.0, 67),
      _note(3.0, 3.5, 69),
      _note(3.5, 4.0, 65),
      
      // Frase 3: C D C A F
      _note(4.5, 5.0, 72),
      _note(5.0, 5.5, 74),
      _note(5.5, 6.0, 72),
      _note(6.0, 6.5, 69),
      _note(6.5, 7.0, 65),
      
      // Frase 4: G A F
      _note(7.5, 8.0, 67),
      _note(8.0, 8.5, 69),
      _note(8.5, 9.0, 65),
      
      // Final frase: G F F
      _note(9.5, 10.0, 67),
      _note(10.0, 10.5, 65),
      _note(10.5, 11.5, 65),
    ];

    // Loop de 64 segundos (aprox 4 repeticiones de un bloque de 16s)
    final List<NoteEvent> extendedNotes = <NoteEvent>[];
    for (int i = 0; i < 4; i++) {
      final double offset = i * 16.0;
      for (final note in notes) {
        extendedNotes.add(
          NoteEvent(
            startTime: note.startTime + offset,
            endTime: note.endTime + offset,
            midiNote: note.midiNote,
            velocity: note.velocity,
          ),
        );
      }
    }

    return Score(
      id: 'demo-bare-necessities',
      title: 'BUSCA LO MÁS VITAL (EL LIBRO DE LA SELVA)',
      audioPath: 'assets/audio/ode_to_joy.mp3', // Placeholder until another one is added
      noteEvents: extendedNotes,
      duration: 64.0,
      createdAt: now.subtract(const Duration(minutes: 1)), // Ligeramente antes que el otro demo
      updatedAt: now,
    );
  }

  static NoteEvent _note(double start, double end, int pitch) {
    return NoteEvent(
      startTime: start,
      endTime: end,
      midiNote: pitch,
      velocity: 80,
    );
  }
}

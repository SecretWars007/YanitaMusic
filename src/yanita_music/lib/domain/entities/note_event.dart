import 'package:equatable/equatable.dart';

/// Entidad que representa un evento musical de nota.
///
/// Modela una nota individual detectada por el sistema de transcripción,
/// incluyendo onset/offset en tiempo, pitch MIDI y velocidad.
class NoteEvent extends Equatable {
  /// Tiempo de inicio de la nota en segundos.
  final double startTime;

  /// Tiempo de finalización de la nota en segundos.
  final double endTime;

  /// Número de nota MIDI (21=A0 a 108=C8 para piano).
  final int midiNote;

  /// Velocidad MIDI (0-127).
  final int velocity;

  /// Confianza del modelo en la detección (0.0 a 1.0).
  final double confidence;

  const NoteEvent({
    required this.startTime,
    required this.endTime,
    required this.midiNote,
    required this.velocity,
    this.confidence = 1.0,
  });

  /// Duración de la nota en segundos.
  double get duration => endTime - startTime;

  /// Alias for [midiNote] used by export utilities.
  int get midiPitch => midiNote;

  /// Nombre de la nota en notación científica (e.g., "C4", "A#3").
  String get noteName {
    const noteNames = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final octave = (midiNote ~/ 12) - 1;
    final noteIndex = midiNote % 12;
    return '${noteNames[noteIndex]}$octave';
  }

  NoteEvent copyWith({
    double? startTime,
    double? endTime,
    int? midiNote,
    int? velocity,
    double? confidence,
  }) {
    return NoteEvent(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      midiNote: midiNote ?? this.midiNote,
      velocity: velocity ?? this.velocity,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [
    startTime,
    endTime,
    midiNote,
    velocity,
    confidence,
  ];
}

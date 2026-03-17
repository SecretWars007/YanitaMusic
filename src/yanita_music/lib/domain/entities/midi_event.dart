import 'package:equatable/equatable.dart';

/// Entidad que representa un evento MIDI estándar.
///
/// Compatible con el formato MIDI estándar para exportación.
class MidiEvent extends Equatable {
  /// Tipo de evento: noteOn, noteOff, controlChange, etc.
  final MidiEventType type;

  /// Canal MIDI (0-15), siempre 0 para piano single-channel.
  final int channel;

  /// Nota MIDI (0-127).
  final int note;

  /// Velocidad (0-127).
  final int velocity;

  /// Tick absoluto en el timeline MIDI.
  final int tick;

  /// Tiempo en segundos (para referencia).
  final double timeSeconds;

  const MidiEvent({
    required this.type,
    this.channel = 0,
    required this.note,
    required this.velocity,
    required this.tick,
    required this.timeSeconds,
  });

  @override
  List<Object?> get props => [type, channel, note, velocity, tick, timeSeconds];
}

enum MidiEventType { noteOn, noteOff, controlChange, programChange, tempo }

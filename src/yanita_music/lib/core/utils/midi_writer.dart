import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/note_event.dart';
import '../constants/app_constants.dart';

/// Escritor de archivos MIDI estándar (formato 0, una pista)
/// compatible con reproductores y editores convencionales.
class MidiWriter {
  MidiWriter({
    this.ticksPerQuarter = AppConstants.defaultDivisions,
    this.tempo = AppConstants.defaultTempo,
  });

  final int ticksPerQuarter;
  final int tempo;

  /// Genera archivo MIDI en memoria.
  Uint8List generate(List<NoteEvent> notes) {
    final trackBytes = _buildTrack(notes);
    final header = _buildHeader(trackBytes.length);

    final output = BytesBuilder()
      ..add(header)
      ..add(trackBytes);

    return output.toBytes();
  }

  /// Genera y guarda en disco.
  Future<String> generateAndSave({
    required List<NoteEvent> notes,
    required String outputPath,
  }) async {
    final bytes = generate(notes);
    final file = File(outputPath);
    await file.writeAsBytes(bytes, flush: true);
    return outputPath;
  }

  Uint8List _buildHeader(int trackLength) {
    final header = BytesBuilder()
      // MThd
      ..add([0x4D, 0x54, 0x68, 0x64])
      // Longitud del header (6 bytes)
      ..add(_uint32(6))
      // Formato 0 (pista única)
      ..add(_uint16(0))
      // Número de pistas
      ..add(_uint16(1))
      // Ticks por negra
      ..add(_uint16(ticksPerQuarter));

    return header.toBytes();
  }

  Uint8List _buildTrack(List<NoteEvent> notes) {
    final events = BytesBuilder();

    // Evento de tempo
    final microsecondsPerBeat = (60000000 / tempo).round();
    events
      ..add(_variableLength(0)) // delta time 0
      ..add([0xFF, 0x51, 0x03])
      ..add([
        (microsecondsPerBeat >> 16) & 0xFF,
        (microsecondsPerBeat >> 8) & 0xFF,
        microsecondsPerBeat & 0xFF,
      ]);

    // Programa: Acoustic Grand Piano (programa 0)
    events
      ..add(_variableLength(0))
      ..add([0xC0, 0x00]);

    // Ordenar notas por tiempo de inicio
    final sorted = List<NoteEvent>.from(notes)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Crear lista de eventos Note On/Off ordenados cronológicamente
    final midiEvents = <_MidiEvent>[];

    for (final note in sorted) {
      final startTick = _secondsToTicks(note.startTime);
      final endTick = _secondsToTicks(note.startTime + note.duration);
      final pitch = note.midiPitch.clamp(0, 127);
      final velocity = note.velocity.clamp(0, 127);

      midiEvents
        ..add(
          _MidiEvent(
            tick: startTick,
            status: 0x90,
            data1: pitch,
            data2: velocity,
          ),
        )
        ..add(_MidiEvent(tick: endTick, status: 0x80, data1: pitch, data2: 0));
    }

    midiEvents.sort((a, b) => a.tick.compareTo(b.tick));

    // Escribir eventos con delta time
    var previousTick = 0;
    for (final event in midiEvents) {
      final delta = (event.tick - previousTick).clamp(0, 0x0FFFFFFF);
      events
        ..add(_variableLength(delta))
        ..add([event.status, event.data1, event.data2]);
      previousTick = event.tick;
    }

    // End of track
    events
      ..add(_variableLength(0))
      ..add([0xFF, 0x2F, 0x00]);

    final trackData = events.toBytes();

    // MTrk + longitud
    final track = BytesBuilder()
      ..add([0x4D, 0x54, 0x72, 0x6B])
      ..add(_uint32(trackData.length))
      ..add(trackData);

    return track.toBytes();
  }

  int _secondsToTicks(double seconds) {
    final beatsPerSecond = tempo / 60.0;
    final beats = seconds * beatsPerSecond;
    return (beats * ticksPerQuarter).round();
  }

  List<int> _uint32(int value) => [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  List<int> _uint16(int value) => [(value >> 8) & 0xFF, value & 0xFF];

  List<int> _variableLength(int value) {
    if (value < 0x80) return [value];

    final result = <int>[];
    var v = value;
    result.add(v & 0x7F);
    v >>= 7;

    while (v > 0) {
      result.add((v & 0x7F) | 0x80);
      v >>= 7;
    }

    return result.reversed.toList();
  }
}

class _MidiEvent {
  const _MidiEvent({
    required this.tick,
    required this.status,
    required this.data1,
    required this.data2,
  });

  final int tick;
  final int status;
  final int data1;
  final int data2;
}

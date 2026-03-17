import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';
import 'package:yanita_music/domain/entities/note_event.dart';

/// Utilidad para generar archivos MIDI estándar (Format 0).
///
/// Convierte una lista de NoteEvent en un archivo MIDI binario
/// compatible con cualquier software de notación musical.
class MidiUtils {
  final Logger _logger = Logger();

  static const int _ticksPerQuarter = 480;
  static const int _midiFileFormat = 0; // Single track
  static const int _numTracks = 1;

  /// Genera un archivo MIDI a partir de eventos de nota.
  ///
  /// [noteEvents] Lista de notas detectadas.
  /// [tempo] BPM del tempo detectado o por defecto.
  /// Retorna la ruta del archivo MIDI generado.
  Future<String> generateMidiFile(
    List<NoteEvent> noteEvents,
    double tempo,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(directory.path, 'exports', 'score_$timestamp.mid');

    // Crear directorio si no existe
    await Directory(p.dirname(filePath)).create(recursive: true);

    final midiBytes = _buildMidiBytes(noteEvents, tempo);

    await File(filePath).writeAsBytes(midiBytes);
    _logger.i('Archivo MIDI generado: $filePath');

    return filePath;
  }

  /// Construye los bytes del archivo MIDI completo.
  Uint8List _buildMidiBytes(List<NoteEvent> noteEvents, double tempo) {
    final builder = BytesBuilder();

    // Header chunk: MThd
    builder.add([0x4D, 0x54, 0x68, 0x64]); // "MThd"
    builder.add(_int32ToBytes(6)); // Header length
    builder.add(_int16ToBytes(_midiFileFormat));
    builder.add(_int16ToBytes(_numTracks));
    builder.add(_int16ToBytes(_ticksPerQuarter));

    // Track chunk
    final trackData = _buildTrackData(noteEvents, tempo);
    builder.add([0x4D, 0x54, 0x72, 0x6B]); // "MTrk"
    builder.add(_int32ToBytes(trackData.length));
    builder.add(trackData);

    return builder.toBytes();
  }

  /// Construye los datos de la pista MIDI.
  Uint8List _buildTrackData(List<NoteEvent> noteEvents, double tempo) {
    final events = <_MidiTrackEvent>[];

    // Evento de tempo
    final microsecondsPerBeat = (60000000 / tempo).round();
    events.add(
      _MidiTrackEvent(
        deltaTick: 0,
        data: [
          0xFF,
          0x51,
          0x03,
          (microsecondsPerBeat >> 16) & 0xFF,
          (microsecondsPerBeat >> 8) & 0xFF,
          microsecondsPerBeat & 0xFF,
        ],
      ),
    );

    // Program Change: Piano (program 0)
    events.add(_MidiTrackEvent(deltaTick: 0, data: [0xC0, 0x00]));

    // Convertir NoteEvents a MIDI events
    final midiNoteEvents = <_TimedMidiEvent>[];

    for (final note in noteEvents) {
      final startTick = _secondsToTicks(note.startTime, tempo);
      final endTick = _secondsToTicks(note.endTime, tempo);

      midiNoteEvents.add(
        _TimedMidiEvent(
          absoluteTick: startTick,
          data: [0x90, note.midiNote, note.velocity], // Note On
        ),
      );

      midiNoteEvents.add(
        _TimedMidiEvent(
          absoluteTick: endTick,
          data: [0x80, note.midiNote, 0x00], // Note Off
        ),
      );
    }

    // Ordenar por tick absoluto
    midiNoteEvents.sort((a, b) => a.absoluteTick.compareTo(b.absoluteTick));

    // Convertir a delta ticks
    var lastTick = 0;
    for (final event in midiNoteEvents) {
      final deltaTick = event.absoluteTick - lastTick;
      events.add(
        _MidiTrackEvent(
          deltaTick: deltaTick.clamp(0, 0x7FFFFFFF),
          data: event.data,
        ),
      );
      lastTick = event.absoluteTick;
    }

    // End of Track
    events.add(_MidiTrackEvent(deltaTick: 0, data: [0xFF, 0x2F, 0x00]));

    // Serializar eventos
    final builder = BytesBuilder();
    for (final event in events) {
      builder.add(_encodeVariableLength(event.deltaTick));
      builder.add(event.data);
    }

    return builder.toBytes();
  }

  int _secondsToTicks(double seconds, double tempo) {
    return (seconds * tempo / 60.0 * _ticksPerQuarter).round();
  }

  /// Codifica un entero como Variable Length Quantity (VLQ) MIDI.
  List<int> _encodeVariableLength(int value) {
    if (value < 0) value = 0;

    final bytes = <int>[];
    bytes.add(value & 0x7F);
    value >>= 7;

    while (value > 0) {
      bytes.add((value & 0x7F) | 0x80);
      value >>= 7;
    }

    return bytes.reversed.toList();
  }

  List<int> _int32ToBytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  List<int> _int16ToBytes(int value) {
    return [(value >> 8) & 0xFF, value & 0xFF];
  }
}

class _MidiTrackEvent {
  final int deltaTick;
  final List<int> data;

  _MidiTrackEvent({required this.deltaTick, required this.data});
}

class _TimedMidiEvent {
  final int absoluteTick;
  final List<int> data;

  _TimedMidiEvent({required this.absoluteTick, required this.data});
}

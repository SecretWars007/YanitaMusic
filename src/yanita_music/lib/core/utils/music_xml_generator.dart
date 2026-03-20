import 'dart:io';

import '../../domain/entities/note_event.dart';
import '../constants/app_constants.dart';

/// Genera archivos MusicXML válidos a partir de eventos MIDI transcritos.
/// Produce partituras con clave de sol orientadas a piano.
class MusicXmlGenerator {
  MusicXmlGenerator({
    this.divisions = AppConstants.defaultDivisions,
    this.tempo = AppConstants.defaultTempo,
    this.timeNumerator = 4,
    this.timeDenominator = 4,
  });

  final int divisions;
  final int tempo;
  final int timeNumerator;
  final int timeDenominator;

  static const _header =
      '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN" '
      '"http://www.musicxml.org/dtds/partwise.dtd">\n';

  /// Mapeo de pitch MIDI a nombre de paso (Step) de la nota.
  /// Los semitonos se manejan con el tag `alter` vía [_alterations].

  static const _noteSteps = [
    'C',
    'C',
    'D',
    'D',
    'E',
    'F',
    'F',
    'G',
    'G',
    'A',
    'A',
    'B',
  ];

  static const _alterations = [0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0];

  /// Convierte lista de [NoteEvent] a un string MusicXML completo.
  String generate({
    required List<NoteEvent> notes,
    String title = 'Transcripción Piano',
    String creator = 'AMOR Piano AMT',
  }) {
    final buffer = StringBuffer()..write(_header);
    buffer.writeln('<score-partwise version="4.0">');

    _writeIdentification(buffer, title, creator);
    _writePartList(buffer);
    _writePart(buffer, notes);

    buffer.writeln('</score-partwise>');
    return buffer.toString();
  }

  /// Escribe el archivo MusicXML en disco.
  Future<String> generateAndSave({
    required List<NoteEvent> notes,
    required String outputPath,
    String title = 'Transcripción Piano',
  }) async {
    final xml = generate(notes: notes, title: title);
    final file = File(outputPath);
    await file.writeAsString(xml, flush: true);
    return outputPath;
  }

  void _writeIdentification(StringBuffer buffer, String title, String creator) {
    buffer
      ..writeln('  <work>')
      ..writeln('    <work-title>$title</work-title>')
      ..writeln('  </work>')
      ..writeln('  <identification>')
      ..writeln('    <creator type="composer">$creator</creator>')
      ..writeln('    <encoding>')
      ..writeln('      <software>AMOR Piano AMT v0.1</software>')
      ..writeln(
        '      <encoding-date>${DateTime.now().toIso8601String().substring(0, 10)}</encoding-date>',
      )
      ..writeln('    </encoding>')
      ..writeln('  </identification>');
  }

  void _writePartList(StringBuffer buffer) {
    buffer
      ..writeln('  <part-list>')
      ..writeln('    <score-part id="P1">')
      ..writeln('      <part-name>Piano</part-name>')
      ..writeln('      <score-instrument id="P1-I1">')
      ..writeln(
        '        <instrument-name>Acoustic Grand Piano</instrument-name>',
      )
      ..writeln('      </score-instrument>')
      ..writeln('      <midi-instrument id="P1-I1">')
      ..writeln('        <midi-channel>1</midi-channel>')
      ..writeln('        <midi-program>1</midi-program>')
      ..writeln('      </midi-instrument>')
      ..writeln('    </score-part>')
      ..writeln('  </part-list>');
  }

  void _writePart(StringBuffer buffer, List<NoteEvent> notes) {
    buffer.writeln('  <part id="P1">');

    final measures = _splitIntoMeasures(notes);

    for (var i = 0; i < measures.length; i++) {
      buffer.writeln('    <measure number="${i + 1}">');

      if (i == 0) {
        _writeAttributes(buffer);
        _writeDirection(buffer);
      }

      _writeMeasureNotes(buffer, measures[i]);
      buffer.writeln('    </measure>');
    }

    buffer.writeln('  </part>');
  }

  void _writeAttributes(StringBuffer buffer) {
    buffer
      ..writeln('      <attributes>')
      ..writeln('        <divisions>$divisions</divisions>')
      ..writeln('        <key>')
      ..writeln('          <fifths>0</fifths>')
      ..writeln('          <mode>major</mode>')
      ..writeln('        </key>')
      ..writeln('        <time>')
      ..writeln('          <beats>$timeNumerator</beats>')
      ..writeln('          <beat-type>$timeDenominator</beat-type>')
      ..writeln('        </time>')
      ..writeln('        <clef>')
      ..writeln('          <sign>G</sign>')
      ..writeln('          <line>2</line>')
      ..writeln('        </clef>')
      ..writeln('      </attributes>');
  }

  void _writeDirection(StringBuffer buffer) {
    buffer
      ..writeln('      <direction placement="above">')
      ..writeln('        <direction-type>')
      ..writeln('          <metronome>')
      ..writeln('            <beat-unit>quarter</beat-unit>')
      ..writeln('            <per-minute>$tempo</per-minute>')
      ..writeln('          </metronome>')
      ..writeln('        </direction-type>')
      ..writeln('        <sound tempo="$tempo"/>')
      ..writeln('      </direction>');
  }

  /// Divide notas en compases basándose en el tiempo.
  List<List<NoteEvent>> _splitIntoMeasures(List<NoteEvent> notes) {
    if (notes.isEmpty) return [[]];

    final sorted = List<NoteEvent>.from(notes)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final measureDuration =
        (timeNumerator / timeDenominator) * (4.0 * 60.0 / tempo);

    final totalTime =
        sorted.last.startTime + sorted.last.duration + measureDuration;
    final measureCount = (totalTime / measureDuration).ceil().clamp(1, 9999);

    final measures = List.generate(measureCount, (_) => <NoteEvent>[]);

    for (final note in sorted) {
      final measureIndex = (note.startTime / measureDuration).floor().clamp(
        0,
        measureCount - 1,
      );
      measures[measureIndex].add(note);
    }

    if (measures.isEmpty) measures.add([]);
    return measures;
  }

  void _writeMeasureNotes(StringBuffer buffer, List<NoteEvent> notes) {
    if (notes.isEmpty) {
      buffer
        ..writeln('      <note>')
        ..writeln('        <rest/>')
        ..writeln('        <duration>${divisions * timeNumerator}</duration>')
        ..writeln('        <type>whole</type>')
        ..writeln('      </note>');
      return;
    }

    final sorted = List<NoteEvent>.from(notes)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (var i = 0; i < sorted.length; i++) {
      final note = sorted[i];
      final isChord =
          i > 0 && (note.startTime - sorted[i - 1].startTime).abs() < 0.01;

      final durationDivisions = _durationToDivisions(note.duration);
      final noteType = _durationToType(durationDivisions);
      final pitchInfo = _midiToPitch(note.midiPitch);

      buffer.writeln('      <note>');

      if (isChord) {
        buffer.writeln('        <chord/>');
      }

      buffer
        ..writeln('        <pitch>')
        ..writeln('          <step>${pitchInfo['step']}</step>');

      if (pitchInfo['alter'] != 0) {
        buffer.writeln('          <alter>${pitchInfo['alter']}</alter>');
      }

      buffer
        ..writeln('          <octave>${pitchInfo['octave']}</octave>')
        ..writeln('        </pitch>')
        ..writeln('        <duration>$durationDivisions</duration>')
        ..writeln('        <type>$noteType</type>')
        ..writeln('        <dynamics>')
        ..writeln('          <other-dynamics>${note.velocity}</other-dynamics>')
        ..writeln('        </dynamics>')
        ..writeln('      </note>');
    }
  }

  Map<String, dynamic> _midiToPitch(int midiPitch) {
    final noteIndex = midiPitch % 12;
    final octave = (midiPitch ~/ 12) - 1;

    return {
      'step': _noteSteps[noteIndex],
      'alter': _alterations[noteIndex],
      'octave': octave.clamp(0, 9),
    };
  }

  int _durationToDivisions(double durationSeconds) {
    final beatsPerSecond = tempo / 60.0;
    final beats = durationSeconds * beatsPerSecond;
    return (beats * divisions).round().clamp(1, divisions * timeNumerator * 4);
  }

  String _durationToType(int durationDivisions) {
    final ratio = durationDivisions / divisions;
    if (ratio >= 4.0) return 'whole';
    if (ratio >= 2.0) return 'half';
    if (ratio >= 1.0) return 'quarter';
    if (ratio >= 0.5) return 'eighth';
    if (ratio >= 0.25) return '16th';
    return '32nd';
  }
}

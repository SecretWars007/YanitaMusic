import 'package:xml/xml.dart';
import '../../domain/entities/note_event.dart';
import '../utils/logger.dart';

/// Parsea archivos MusicXML para convertirlos en eventos de nota reproducibles.
/// Soporta estructuras básicas de compases, notas, silencios y acordes.
class MusicXmlParser {
  const MusicXmlParser();

  /// Convierte un string XML de MusicXML a una lista de [NoteEvent].
  List<NoteEvent> parse(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final notes = <NoteEvent>[];
      
      final measures = document.findAllElements('measure');
      double currentTime = 0.0;
      int divisions = 1; // Unidades por negra
      int tempo = 120;   // BPM por defecto

      for (var measure in measures) {
        // 1. Extraer Atributos (Divisions)
        final attr = measure.getElement('attributes');
        if (attr != null) {
          final divsNode = attr.getElement('divisions');
          if (divsNode != null) {
            divisions = int.tryParse(divsNode.innerText) ?? divisions;
          }
        }

        // 2. Extraer Tempo (Direction -> Sound)
        final soundTags = measure.findAllElements('sound');
        for (var sound in soundTags) {
          final tAttr = sound.getAttribute('tempo');
          if (tAttr != null) {
            tempo = double.tryParse(tAttr)?.round() ?? tempo;
          }
        }

        // 3. Procesar Notas y Silencios
        final noteElements = measure.children.whereType<XmlElement>().where((e) => e.name.local == 'note');
        
        for (var noteNode in noteElements) {
          final isRest = noteNode.getElement('rest') != null;
          final durationNode = noteNode.getElement('duration');
          if (durationNode == null) continue;

          final durationDivs = int.tryParse(durationNode.innerText) ?? 1;
          // Segundos = (Divisions de nota / Divisions por negra) * (60 seg / BPM)
          final durationSeconds = (durationDivs / divisions) * (60.0 / tempo);

          if (!isRest) {
            final pitchNode = noteNode.getElement('pitch');
            if (pitchNode != null) {
              final step = pitchNode.getElement('step')?.innerText ?? 'C';
              final octave = int.tryParse(pitchNode.getElement('octave')?.innerText ?? '4') ?? 4;
              final alter = int.tryParse(pitchNode.getElement('alter')?.innerText ?? '0') ?? 0;
              
              final midiPitch = _pitchToMidi(step, octave, alter);
              
              // Los acordes en MusicXML se marcan con <chord/> en las notas subsecuentes.
              // Una nota con <chord/> empieza al mismo tiempo que la nota anterior.
              final isChord = noteNode.getElement('chord') != null;
                final startTime = isChord && notes.isNotEmpty ? notes.last.startTime : currentTime;

                final endTime = startTime + durationSeconds;

                notes.add(NoteEvent(
                  midiNote: midiPitch,
                  startTime: startTime,
                  endTime: endTime,
                  velocity: 80,
                ));
                
                if (!isChord) {
                  currentTime += durationSeconds;
                }

            }
          } else {
            // Es un silencio, solo avanzamos el cursor de tiempo
            currentTime += durationSeconds;
          }
        }
      }
      
      AppLogger.info('MusicXML parseado exitosamente: ${notes.length} notas extraídas.');
      return notes;
    } catch (e) {
      AppLogger.error('Error al parsear MusicXML: $e');
      return [];
    }
  }

  /// Calcula el valor MIDI a partir de la notación MusicXML.
  int _pitchToMidi(String step, int octave, int alter) {
    const stepToOffset = {
      'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11,
    };
    // MIDI = (Octava + 1) * 12 + Offset de Nota + Alteración
    return (octave + 1) * 12 + (stepToOffset[step] ?? 0) + alter;
  }
}

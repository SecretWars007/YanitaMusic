import 'package:flutter/material.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/entities/score.dart';

/// Un visualizador de partituras que dibuja un pentagrama musical
/// y resalta las notas en tiempo real durante la reproducción.
class ScoreStaveVisualizer extends StatelessWidget {
  final Score score;
  final double currentTime;
  final bool isPlaying;
  final bool showNoteNames;

  const ScoreStaveVisualizer({
    super.key,
    required this.score,
    required this.currentTime,
    this.isPlaying = false,
    this.showNoteNames = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260, // Aumentado de 200 a 260 para mejor visibilidad
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD), // Blanco roto más premium
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _StavePainter(
            noteEvents: score.noteEvents,
            currentTime: currentTime,
            accentColor: Theme.of(context).colorScheme.primary,
            showNoteNames: showNoteNames,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _StavePainter extends CustomPainter {
  final List<NoteEvent> noteEvents;
  final double currentTime;
  final Color accentColor;
  final bool showNoteNames;

  _StavePainter({
    required this.noteEvents,
    required this.currentTime,
    required this.accentColor,
    this.showNoteNames = true,
  });

  @override
  @override
  void paint(Canvas canvas, Size size) {
    const double paddingH = 50.0;
    // Pentagrama ocupa un poco más de alto
    final double staveHeight = size.height * 0.55; 
    final double lineSpacing = staveHeight / 4;
    final double startY = (size.height - staveHeight) / 2;

    // 1. Dibujar clave de sol usando TextPainter
    final TextPainter clefPainter = TextPainter(
      text: TextSpan(
        text: '𝄞',
        style: TextStyle(
          fontSize: lineSpacing * 4.8, // Escala más profesional (antes era 6)
          color: Colors.black.withValues(alpha: 0.9),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    clefPainter.layout();
    
    // Posicionar la clave: el "bucle" debe estar centrado en la 2da línea (Sol)
    const double clefX = paddingH * 0.2;
    final double clefY = startY - lineSpacing * 0.9; 
    clefPainter.paint(canvas, Offset(clefX, clefY));

    final Paint linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.5; // Líneas un poco más gruesas

    // 2. Dibujar las 5 líneas del pentagrama
    for (int i = 0; i < 5; i++) {
      final y = startY + (i * lineSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    if (noteEvents.isEmpty) {
      return;
    }

    // 4. Dibujar notas (OPTIMIZADO: Solo las visibles)
    const double timeWindow = 6.0;
    final double pixelsPerSecond = (size.width - paddingH * 2) / timeWindow;
    final double playheadX = size.width * 0.3;

    // Buscar el rango de notas visibles usando búsqueda binaria simple
    // Esto es vital para partituras de miles de notas.
    final int startIndex = _findFirstVisibleNote(currentTime - 2.0); // 2s de margen atrás
    final int endIndex = _findFirstVisibleNote(currentTime + timeWindow + 1.0);

    for (int i = startIndex; i < endIndex && i < noteEvents.length; i++) {
      final note = noteEvents[i];
      final double x = playheadX + (note.startTime - currentTime) * pixelsPerSecond;

      if (x < -50 || x > size.width + 50) continue;

      // Mapeo MIDI a Posición Y
      final int midi = note.midiNote;
      final int octave = (midi ~/ 12) - 1;
      final int noteInOctave = midi % 12;
      
      int step = octave * 7;
      if (noteInOctave <= 1) {
        step += 0; // C
      } else if (noteInOctave <= 3) {
        step += 1; // D
      } else if (noteInOctave <= 4) {
        step += 2; // E
      } else if (noteInOctave <= 6) {
        step += 3; // F
      } else if (noteInOctave <= 8) {
        step += 4; // G
      } else if (noteInOctave <= 10) {
        step += 5; // A
      } else {
        step += 6; // B
      }

      // Ref: E4 (64) es el paso 30. Línea inferior = startY + 4 * lineSpacing
      final double y = (startY + 4 * lineSpacing) - (step - 30) * (lineSpacing / 2);

      final bool isActive = currentTime >= note.startTime && currentTime <= note.endTime;

      // Dibujar líneas adicionales (Ledger Lines)
      final Paint ledgerPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      
      if (step <= 28) {
        for (int s = 28; s >= step; s -= 2) {
          final double ly = (startY + 4 * lineSpacing) - (s - 30) * (lineSpacing / 2);
          canvas.drawLine(Offset(x - 18, ly), Offset(x + 18, ly), ledgerPaint);
        }
      }
      if (step >= 40) {
        for (int s = 40; s <= step; s += 2) {
          final double ly = (startY + 4 * lineSpacing) - (s - 30) * (lineSpacing / 2);
          canvas.drawLine(Offset(x - 18, ly), Offset(x + 18, ly), ledgerPaint);
        }
      }

      final Color noteColor = isActive ? accentColor : Colors.black.withValues(alpha: 0.9);
      final Paint notePaint = Paint()
        ..color = noteColor
        ..strokeWidth = 2.5 // Borde grueso como en la imagen
        ..style = PaintingStyle.stroke; // Estilo "hollow" (hueco)

      // Notas con proporciones de la imagen (más ovaladas)
      const double radiusX = 11.0;
      const double radiusY = 8.5;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.25); 

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        notePaint,
      );

      if (isActive) {
        // Relleno sutil para nota activa sin perder el estilo hollow
        final Paint activeFill = Paint()
          ..color = accentColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: radiusX * 2,
            height: radiusY * 2,
          ),
          activeFill,
        );
      }
      canvas.restore();

      // 5. Dibujar nombre de la nota (Do, Re, Mi...) debajo SI está habilitado
      if (showNoteNames) {
        final String noteName = _getNoteName(noteInOctave);
        final TextPainter namePainter = TextPainter(
          text: TextSpan(
            text: noteName,
            style: TextStyle(
              color: noteColor.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        namePainter.layout();
        namePainter.paint(canvas, Offset(x - namePainter.width / 2, startY + staveHeight + 8));
      }

      final bool stemUp = step < 34;
      final double stemHeight = lineSpacing * 3.5;
      final double stemX = stemUp ? x + radiusX * 0.8 : x - radiusX * 0.8;
      final double stemEndY = stemUp ? y - stemHeight : y + stemHeight;

      canvas.drawLine(
        Offset(stemX, y),
        Offset(stemX, stemEndY),
        Paint()
          ..color = noteColor
          ..strokeWidth = 2.0,
      );
    }
    
    // (Resto del código del playhead...)
    // 4. Dibujar línea de tiempo (Playhead) - Más visible y elegante
    final Paint playheadPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 3.0;
    
    // Línea principal
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, size.height),
      playheadPaint,
    );
    
    // Triángulo arriba del playhead
    final Path arrowPath = Path()
      ..moveTo(playheadX - 8, 0)
      ..lineTo(playheadX + 8, 0)
      ..lineTo(playheadX, 12)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = accentColor);
  }

  /// Búsqueda binaria para encontrar la primera nota que podría ser visible.
  int _findFirstVisibleNote(double targetTime) {
    if (noteEvents.isEmpty) return 0;
    
    int low = 0;
    int high = noteEvents.length - 1;
    
    while (low <= high) {
      final int mid = low + (high - low) ~/ 2;
      if (noteEvents[mid].startTime < targetTime) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Retorna el nombre de la nota en solfeo según el índice (0-11).
  String _getNoteName(int noteInOctave) {
    switch (noteInOctave) {
      case 0: return 'Do';
      case 1: return 'Do#';
      case 2: return 'Re';
      case 3: return 'Re#';
      case 4: return 'Mi';
      case 5: return 'Fa';
      case 6: return 'Fa#';
      case 7: return 'Sol';
      case 8: return 'Sol#';
      case 9: return 'La';
      case 10: return 'La#';
      case 11: return 'Si';
      default: return '';
    }
  }

  @override
  bool shouldRepaint(covariant _StavePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.noteEvents != noteEvents ||
        oldDelegate.showNoteNames != showNoteNames;
  }
}

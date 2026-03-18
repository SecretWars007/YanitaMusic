import 'package:flutter/material.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/entities/score.dart';

/// Un visualizador de partituras que dibuja un pentagrama musical
/// y resalta las notas en tiempo real durante la reproducción.
class ScoreStaveVisualizer extends StatelessWidget {
  final Score score;
  final double currentTime;
  final bool isPlaying;

  const ScoreStaveVisualizer({
    super.key,
    required this.score,
    required this.currentTime,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _StavePainter(
            noteEvents: score.noteEvents,
            currentTime: currentTime,
            accentColor: const Color(0xFFFF9800),
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

  _StavePainter({
    required this.noteEvents,
    required this.currentTime,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double padding = 40.0;
    final double staveHeight = size.height * 0.6;
    final double lineSpacing = staveHeight / 4;
    final double startY = (size.height - staveHeight) / 2;

    // 1. Dibujar clave de sol (simplificada)
    final Paint clefPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final Path clefPath = Path();
    clefPath.moveTo(padding * 0.5, startY + staveHeight + 10);
    clefPath.quadraticBezierTo(padding * 0.8, startY - 20, padding * 0.5, startY + staveHeight * 0.5);
    canvas.drawPath(clefPath, clefPaint);

    final Paint linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    // 2. Dibujar las 5 líneas del pentagrama
    for (int i = 0; i < 5; i++) {
      final y = startY + (i * lineSpacing);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    if (noteEvents.isEmpty) return;

    // 3. Parámetros de visualización temporal
    const double timeWindow = 5.0;
    final double pixelsPerSecond = (size.width - padding * 2) / timeWindow;
    final double playheadX = size.width * 0.25;

    // 4. Dibujar notas
    for (final note in noteEvents) {
      final double x = playheadX + (note.startTime - currentTime) * pixelsPerSecond;
      if (x < -50 || x > size.width + 50) continue;

      // Mapeo MIDI a Posición Y:
      // E4 = 64 (Línea de abajo del pentagrama) -> index 0 (desde abajo)
      // F4 = 65 (Primer espacio)
      // G4 = 67 (Segunda línea)
      // C4 = 60 (Una línea adicional por debajo)
      
      // Calculamos "pasos" de medio espacio desde C4 (60)
      // Usamos una escala diatónica simplificada para el mapeo visual
      final int midi = note.midiNote;
      final int octave = (midi ~/ 12) - 1;
      final int noteInOctave = midi % 12;
      
      // Encontrar el paso diatónico más cercano
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

      // Ref: E4 (64) es el paso 4*7 + 2 = 30
      // La línea de abajo del pentagrama (E4) es startY + 4 * lineSpacing
      // Cada paso diatónico es lineSpacing / 2
      final double y = (startY + 4 * lineSpacing) - (step - 30) * (lineSpacing / 2);

      final bool isActive = currentTime >= note.startTime && currentTime <= note.endTime;

      // Dibujar líneas adicionales (Ledger Lines)
      final Paint ledgerPaint = Paint()
        ..color = Colors.white38
        ..strokeWidth = 1.0;
      
      // Línea para C4 (step 28)
      if (step <= 28) {
        for (int s = 28; s >= step; s -= 2) {
          final double ly = (startY + 4 * lineSpacing) - (s - 30) * (lineSpacing / 2);
          canvas.drawLine(Offset(x - 12, ly), Offset(x + 12, ly), ledgerPaint);
        }
      }
      // Línea para A5 (step 40) y superiores
      if (step >= 40) {
        for (int s = 40; s <= step; s += 2) {
          final double ly = (startY + 4 * lineSpacing) - (s - 30) * (lineSpacing / 2);
          canvas.drawLine(Offset(x - 12, ly), Offset(x + 12, ly), ledgerPaint);
        }
      }

      final Paint notePaint = Paint()
        ..color = isActive ? accentColor : Colors.white70
        ..style = PaintingStyle.fill;

      final double radiusX = isActive ? 8.0 : 6.0;
      final double radiusY = isActive ? 6.0 : 4.5;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        notePaint,
      );

      if (isActive) {
        final Paint borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: radiusX * 2,
            height: radiusY * 2,
          ),
          borderPaint,
        );
      }

      const double stemHeight = 30.0;
      final double stemX = x + radiusX - 1;
      canvas.drawLine(
        Offset(stemX, y),
        Offset(stemX, y - stemHeight),
        notePaint..strokeWidth = isActive ? 2.5 : 1.5,
      );
    }

    // 4. Dibujar línea de tiempo (Playhead)
    final Paint playheadPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.5)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(playheadX, startY - 10),
      Offset(playheadX, startY + staveHeight + 10),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StavePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.noteEvents != noteEvents;
  }
}

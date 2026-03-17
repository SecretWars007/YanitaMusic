import 'package:flutter/material.dart';
import 'package:yanita_music/domain/entities/score.dart';

/// Página de detalle de una partitura transcrita.
class ScoreDetailPage extends StatelessWidget {
  final Score score;

  const ScoreDetailPage({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(score.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información general
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de la Partitura',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(context, 'Título', score.title),
                    _buildDetailRow(
                      context,
                      'Duración',
                      '${score.duration.toStringAsFixed(1)} segundos',
                    ),
                    _buildDetailRow(
                      context,
                      'Notas detectadas',
                      '${score.noteCount}',
                    ),
                    _buildDetailRow(
                      context,
                      'Tempo',
                      score.tempo != null
                          ? '${score.tempo!.toStringAsFixed(0)} BPM'
                          : 'No detectado',
                    ),
                    _buildDetailRow(
                      context,
                      'Tipo',
                      score.isPolyphonic ? 'Polifónica' : 'Monofónica',
                    ),
                    _buildDetailRow(
                      context,
                      'Creada',
                      _formatDate(score.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visualización de notas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas Detectadas',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Divider(height: 24),
                    if (score.noteEvents.isEmpty)
                      const Text('Sin notas registradas')
                    else
                      SizedBox(
                        height: 200,
                        child: _buildPianoRoll(context),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de notas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eventos de Nota (primeros 20)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...score.noteEvents.take(20).map(
                      (note) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              note.noteName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            Text(
                              '${note.startTime.toStringAsFixed(2)}s - '
                              '${note.endTime.toStringAsFixed(2)}s',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              'vel: ${note.velocity}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Visualización tipo piano roll simplificada.
  Widget _buildPianoRoll(BuildContext context) {
    if (score.noteEvents.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    return CustomPaint(
      painter: _PianoRollPainter(
        noteEvents: score.noteEvents,
        accentColor: Theme.of(context).colorScheme.primary,
        goldColor: Theme.of(context).colorScheme.secondary,
      ),
      size: const Size(double.infinity, 200),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, "0")}:'
        '${date.minute.toString().padLeft(2, "0")}';
  }
}

class _PianoRollPainter extends CustomPainter {
  final List noteEvents;
  final Color accentColor;
  final Color goldColor;

  _PianoRollPainter({
    required this.noteEvents,
    required this.accentColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (noteEvents.isEmpty) return;

    // Encontrar rangos
    double minTime = double.infinity;
    double maxTime = 0;
    int minNote = 127;
    int maxNote = 0;

    for (final note in noteEvents) {
      if (note.startTime < minTime) minTime = note.startTime;
      if (note.endTime > maxTime) maxTime = note.endTime;
      if (note.midiNote < minNote) minNote = note.midiNote;
      if (note.midiNote > maxNote) maxNote = note.midiNote;
    }

    final timeRange = maxTime - minTime;
    final noteRange = (maxNote - minNote + 1).clamp(1, 88);
    final noteHeight = size.height / noteRange;

    // Dibujar fondo con líneas de guía
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (var i = 0; i <= noteRange; i++) {
      final y = i * noteHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Dibujar notas
    for (final note in noteEvents) {
      final x = timeRange > 0
          ? ((note.startTime - minTime) / timeRange * size.width)
          : 0.0;
      final w = timeRange > 0
          ? (note.duration / timeRange * size.width).clamp(2.0, size.width)
          : 4.0;
      final y = (maxNote - note.midiNote) * noteHeight;

      final notePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, noteHeight * 0.8),
          const Radius.circular(2),
        ),
        notePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yanita_music/presentation/blocs/transcription/transcription_bloc.dart';
import 'package:yanita_music/presentation/blocs/songbook/songbook_bloc.dart';
import 'package:yanita_music/presentation/blocs/score_library/score_library_bloc.dart';

/// Página de transcripción musical.
///
/// Permite al usuario:
/// 1. Subir un archivo MP3 de piano
/// 2. Ver el progreso del pipeline DSP + TFLite
/// 3. Guardar la partitura resultante
///
/// Incluye alerta informativa de que solo se soporta piano,
/// no voces ni otros instrumentos.
class TranscriptionPage extends StatelessWidget {
  const TranscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcripción Musical'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showPianoOnlyAlert(context),
          ),
        ],
      ),
      body: BlocConsumer<TranscriptionBloc, TranscriptionState>(
        listener: (context, state) {
          if (state is TranscriptionSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Partitura "${state.title}" guardada exitosamente',
                ),
                backgroundColor: Colors.green.shade700,
              ),
            );
            // Refrescar el cancionero y la biblioteca para que aparezcan
            context.read<SongbookBloc>().add(LoadSongs());
            context.read<ScoreLibraryBloc>().add(LoadScores());
            context.read<TranscriptionBloc>().add(ResetTranscription());
            // Ir a la pestaña de Biblioteca (índice 2) si se desea,
            // o simplemente mostrar el mensaje.
            // Navigator.of(context).pop(); // Eliminado para tabs
          }
          if (state is TranscriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Alerta informativa
                _buildInfoBanner(context),
                const SizedBox(height: 24),

                // Área de upload
                if (state is TranscriptionInitial) _buildUploadCard(context),

                if (state is TranscriptionError) _buildErrorCard(context, state),

                if (state is AudioFileSelected)
                  _buildFileSelectedCard(context, state),

                if (state is AudioProcessing)
                  _buildProcessingCard(context, state),

                if (state is Transcribing)
                  _buildTranscribingCard(context, state),

                if (state is SavingTranscription)
                  _buildSavingCard(context, state),

                if (state is TranscriptionSuccess)
                  _buildSuccessCard(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.piano, color: Colors.amber.shade300, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Solo se puede transcribir música de piano. '
              'Voces y otros instrumentos no son soportados.',
              style: TextStyle(color: Colors.amber.shade100, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.read<TranscriptionBloc>().add(SelectAudioFile()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(height: 16),
              Text(
                'Seleccionar archivo de audio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Formatos soportados: MP3, WAV, M4A, FLAC',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Tamaño máximo: 50 MB',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFFFF9800),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'TIP: Si no ves tus archivos, usa el menú lateral en "Recientes".',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSelectedCard(BuildContext context, AudioFileSelected state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.audio_file,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              state.fileName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.read<TranscriptionBloc>().add(
                    ResetTranscription(),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.read<TranscriptionBloc>().add(
                    StartTranscription(filePath: state.filePath),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Transcribir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard(BuildContext context, AudioProcessing state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              state.statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(state.fileName, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              backgroundColor: Colors.white10,
              color: Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscribingCard(BuildContext context, Transcribing state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              state.statusMessage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Modelo: Onsets and Frames (TFLite)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingCard(BuildContext context, SavingTranscription state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFFF9800),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Guardando "${state.title}"...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Almacenando en la base de datos local',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context, TranscriptionSuccess state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              '¡Transcripción completada!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Notas detectadas', '${state.noteCount}'),
            _buildMetricRow(
              'Duración',
              '${state.duration.toStringAsFixed(1)}s',
            ),
            _buildMetricRow(
              'Tipo',
              state.isPolyphonic ? 'Polifónica' : 'Monofónica',
            ),
            const SizedBox(height: 24),
            const Text(
              'La partitura se ha guardado automáticamente en tu biblioteca.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<TranscriptionBloc>().add(
                ResetTranscription(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Nueva Transcripción'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, TranscriptionError state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al procesar archivo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.read<TranscriptionBloc>().add(
                    ResetTranscription(),
                  ),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Otro archivo'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.read<TranscriptionBloc>().add(
                    RetryTranscription(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPianoOnlyAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.piano, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 12),
            const Text('Solo Piano'),
          ],
        ),
        content: const Text(
          'Este sistema de transcripción automática (AMT) está diseñado '
          'exclusivamente para piano electrónico.\n\n'
          'No es posible transcribir:\n'
          '• Voces humanas\n'
          '• Guitarras u otros instrumentos\n'
          '• Mezclas de múltiples instrumentos\n\n'
          'Para mejores resultados, usa grabaciones de piano solo '
          'en formato MP3 o WAV.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

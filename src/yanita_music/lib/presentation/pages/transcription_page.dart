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

                if (state is TranscriptionError)
                  _buildErrorCard(context, state, state.steps),

                if (state is AudioFileSelected)
                  _buildFileSelectedCard(context, state),

                if (state is AudioProcessing)
                  _buildProcessingCard(context, state, state.steps),

                if (state is Transcribing)
                  _buildProcessingCard(context, state, state.steps),

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
        onTap: () =>
            context.read<TranscriptionBloc>().add(const SelectAudioFile()),
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

  Widget _buildProcessingCard(BuildContext context, TranscriptionState state, List<TranscriptionStep> steps) {
    String title = 'Procesando...';
    String fileName = '';
    String? detail;

    if (state is AudioProcessing) {
      title = state.statusMessage;
      fileName = state.fileName;
      detail = state.detailMessage;
    } else if (state is Transcribing) {
      title = state.statusMessage;
      fileName = state.fileName;
      detail = state.detailMessage;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF9800)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      Text(fileName, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildStepsList(context, steps),
            if (detail != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.amber),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepsList(BuildContext context, List<TranscriptionStep> steps) {
    return Column(
      children: steps.map((step) => _buildStepRow(context, step)).toList(),
    );
  }

  Widget _buildStepRow(BuildContext context, TranscriptionStep step) {
    IconData icon;
    Color color;
    Widget trailing = const SizedBox.shrink();

    switch (step.status) {
      case TranscriptionStepStatus.pending:
        icon = Icons.radio_button_unchecked;
        color = Colors.white24;
        break;
      case TranscriptionStepStatus.processing:
        icon = Icons.sync;
        color = const Color(0xFFFF9800);
        trailing = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFFF9800)),
        );
        break;
      case TranscriptionStepStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green.shade400;
        break;
      case TranscriptionStepStatus.error:
        icon = Icons.error;
        color = Colors.red.shade400;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                color: step.status == TranscriptionStepStatus.pending ? Colors.white38 : Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          trailing,
        ],
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            _buildMetricRow('Notas detectadas', '${state.noteCount}'),
            _buildMetricRow(
              'Duración',
              '${state.duration.toStringAsFixed(1)}s',
            ),
            _buildMetricRow(
              'Tipo',
              state.isPolyphonic ? 'Polifónica' : 'Monofónica',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.read<TranscriptionBloc>().add(ResetTranscription()),
                icon: const Icon(Icons.refresh),
                label: const Text('Nueva Transcripción'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, TranscriptionError state, List<TranscriptionStep>? steps) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Error en la transcripción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
                  ),
                ),
              ],
            ),
            if (steps != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              _buildStepsList(context, steps),
            ],
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (state.lastFilePath != null) {
                    context.read<TranscriptionBloc>().add(
                          StartTranscription(filePath: state.lastFilePath!),
                        );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
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

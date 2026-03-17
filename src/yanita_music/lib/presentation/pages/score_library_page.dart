import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/presentation/blocs/score_library/score_library_bloc.dart';
import 'package:yanita_music/presentation/pages/score_detail_page.dart';

/// Página de biblioteca de partituras generadas.
class ScoreLibraryPage extends StatelessWidget {
  const ScoreLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Partituras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<ScoreLibraryBloc>().add(LoadScores()),
          ),
        ],
      ),
      body: BlocConsumer<ScoreLibraryBloc, ScoreLibraryState>(
        listener: (context, state) {
          if (state is ScoreExportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Archivo ${state.format} exportado exitosamente',
                ),
                action: SnackBarAction(
                  label: 'Compartir',
                  onPressed: () => Share.shareXFiles(
                    [XFile(state.filePath)],
                  ),
                ),
              ),
            );
            // Reload scores list
            context.read<ScoreLibraryBloc>().add(LoadScores());
          }
          if (state is ScoreLibraryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ScoreLibraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ScoreLibraryEmpty || state is ScoreLibraryInitial) {
            return _buildEmptyState(context);
          }

          if (state is ScoreLibraryLoaded) {
            return _buildScoresList(context, state.scores);
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin partituras aún',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transcribe un archivo MP3 para generar\ntu primera partitura',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildScoresList(BuildContext context, List<Score> scores) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scores.length,
      itemBuilder: (context, index) {
        final score = scores[index];
        return _buildScoreCard(context, score);
      },
    );
  }

  Widget _buildScoreCard(BuildContext context, Score score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ScoreDetailPage(score: score),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${score.noteCount} notas · '
                      '${score.duration.toStringAsFixed(1)}s · '
                      '${score.isPolyphonic ? "Polifónica" : "Monofónica"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'midi':
                      context.read<ScoreLibraryBloc>().add(
                        ExportScoreAsMidi(scoreId: score.id),
                      );
                    case 'xml':
                      context.read<ScoreLibraryBloc>().add(
                        ExportScoreAsMusicXml(scoreId: score.id),
                      );
                    case 'delete':
                      _confirmDelete(context, score);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'midi',
                    child: ListTile(
                      leading: Icon(Icons.file_download),
                      title: Text('Exportar MIDI'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'xml',
                    child: ListTile(
                      leading: Icon(Icons.code),
                      title: Text('Exportar MusicXML'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Eliminar',
                          style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Score score) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar partitura'),
        content: Text('¿Eliminar "${score.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScoreLibraryBloc>().add(
                DeleteScoreEvent(scoreId: score.id),
              );
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

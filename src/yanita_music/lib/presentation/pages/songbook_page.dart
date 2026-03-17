import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yanita_music/domain/entities/song.dart';
import 'package:yanita_music/presentation/blocs/songbook/songbook_bloc.dart';

/// Página del cancionero del usuario.
class SongbookPage extends StatelessWidget {
  const SongbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cancionero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SongbookBloc>().add(LoadSongs()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar canciones...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (query) {
                if (query.isEmpty) {
                  context.read<SongbookBloc>().add(LoadSongs());
                } else {
                  context
                      .read<SongbookBloc>()
                      .add(SearchSongsEvent(query: query));
                }
              },
            ),
          ),

          // Lista de canciones
          Expanded(
            child: BlocBuilder<SongbookBloc, SongbookState>(
              builder: (context, state) {
                if (state is SongbookLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SongbookEmpty || state is SongbookInitial) {
                  return _buildEmptyState(context);
                }

                if (state is SongbookLoaded) {
                  return _buildSongsList(context, state.songs);
                }

                if (state is SongbookError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return _buildEmptyState(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Cancionero vacío',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega canciones desde tus partituras\ntranscritas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList(BuildContext context, List<Song> songs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            title: Text(
              song.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              song.artist ?? 'Artista desconocido',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                song.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: song.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white38,
              ),
              onPressed: () => context
                  .read<SongbookBloc>()
                  .add(ToggleFavorite(song: song)),
            ),
          ),
        );
      },
    );
  }
}

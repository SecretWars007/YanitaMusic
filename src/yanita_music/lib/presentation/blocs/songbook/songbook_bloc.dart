import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/song.dart';
import 'package:yanita_music/domain/usecases/add_song_usecase.dart';
import 'package:yanita_music/domain/usecases/get_songs_usecase.dart';
import 'package:yanita_music/domain/repositories/songbook_repository.dart';

part 'songbook_event.dart';
part 'songbook_state.dart';

/// BLoC para el cancionero del usuario.
class SongbookBloc extends Bloc<SongbookEvent, SongbookState> {
  final GetSongsUseCase _getSongsUseCase;
  final AddSongUseCase _addSongUseCase;
  final SongbookRepository _songbookRepository;

  SongbookBloc({
    required GetSongsUseCase getSongsUseCase,
    required AddSongUseCase addSongUseCase,
    required SongbookRepository songbookRepository,
  })  : _getSongsUseCase = getSongsUseCase,
        _addSongUseCase = addSongUseCase,
        _songbookRepository = songbookRepository,
        super(SongbookInitial()) {
    on<LoadSongs>(_onLoadSongs);
    on<AddSongEvent>(_onAddSong);
    on<SearchSongsEvent>(_onSearchSongs);
    on<ToggleFavorite>(_onToggleFavorite);
    on<FilterByCategory>(_onFilterByCategory);
  }

  Future<void> _onLoadSongs(
    LoadSongs event,
    Emitter<SongbookState> emit,
  ) async {
    emit(SongbookLoading());
    final result = await _getSongsUseCase(const NoParams());
    result.fold(
      (failure) => emit(SongbookError(message: failure.message)),
      (songs) => songs.isEmpty
          ? emit(SongbookEmpty())
          : emit(SongbookLoaded(songs: songs)),
    );
  }

  Future<void> _onAddSong(
    AddSongEvent event,
    Emitter<SongbookState> emit,
  ) async {
    final result = await _addSongUseCase(AddSongParams(song: event.song));
    result.fold(
      (failure) => emit(SongbookError(message: failure.message)),
      (_) => add(LoadSongs()),
    );
  }

  Future<void> _onSearchSongs(
    SearchSongsEvent event,
    Emitter<SongbookState> emit,
  ) async {
    emit(SongbookLoading());
    final result = await _songbookRepository.searchSongs(event.query);
    result.fold(
      (failure) => emit(SongbookError(message: failure.message)),
      (songs) => songs.isEmpty
          ? emit(SongbookEmpty())
          : emit(SongbookLoaded(songs: songs)),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<SongbookState> emit,
  ) async {
    final updated = event.song.copyWith(isFavorite: !event.song.isFavorite);
    final result = await _songbookRepository.updateSong(updated);
    result.fold(
      (failure) => emit(SongbookError(message: failure.message)),
      (_) => add(LoadSongs()),
    );
  }

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<SongbookState> emit,
  ) async {
    emit(SongbookLoading());
    if (event.category == null) {
      add(LoadSongs());
      return;
    }
    final result =
        await _songbookRepository.getSongsByCategory(event.category!);
    result.fold(
      (failure) => emit(SongbookError(message: failure.message)),
      (songs) => songs.isEmpty
          ? emit(SongbookEmpty())
          : emit(SongbookLoaded(
              songs: songs,
              activeCategory: event.category,
            )),
    );
  }
}

part of 'songbook_bloc.dart';

sealed class SongbookState extends Equatable {
  const SongbookState();

  @override
  List<Object?> get props => [];
}

final class SongbookInitial extends SongbookState {}

final class SongbookLoading extends SongbookState {}

final class SongbookLoaded extends SongbookState {
  final List<Song> songs;
  final String? activeCategory;

  const SongbookLoaded({required this.songs, this.activeCategory});

  @override
  List<Object?> get props => [songs, activeCategory];
}

final class SongbookEmpty extends SongbookState {}

final class SongbookError extends SongbookState {
  final String message;

  const SongbookError({required this.message});

  @override
  List<Object?> get props => [message];
}

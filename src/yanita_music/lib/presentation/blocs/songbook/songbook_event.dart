part of 'songbook_bloc.dart';

sealed class SongbookEvent extends Equatable {
  const SongbookEvent();

  @override
  List<Object?> get props => [];
}

final class LoadSongs extends SongbookEvent {}

final class AddSongEvent extends SongbookEvent {
  final Song song;

  const AddSongEvent({required this.song});

  @override
  List<Object?> get props => [song];
}

final class SearchSongsEvent extends SongbookEvent {
  final String query;

  const SearchSongsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

final class ToggleFavorite extends SongbookEvent {
  final Song song;

  const ToggleFavorite({required this.song});

  @override
  List<Object?> get props => [song];
}

final class FilterByCategory extends SongbookEvent {
  final String? category;

  const FilterByCategory({this.category});

  @override
  List<Object?> get props => [category];
}

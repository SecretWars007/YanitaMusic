part of 'score_library_bloc.dart';

/// Estados del BLoC de biblioteca de partituras.
sealed class ScoreLibraryState extends Equatable {
  const ScoreLibraryState();

  @override
  List<Object?> get props => [];
}

final class ScoreLibraryInitial extends ScoreLibraryState {}

final class ScoreLibraryLoading extends ScoreLibraryState {}

final class ScoreLibraryLoaded extends ScoreLibraryState {
  final List<Score> scores;

  const ScoreLibraryLoaded({required this.scores});

  @override
  List<Object?> get props => [scores];
}

final class ScoreLibraryEmpty extends ScoreLibraryState {}

final class ScoreExportSuccess extends ScoreLibraryState {
  final String filePath;
  final String format;

  const ScoreExportSuccess({required this.filePath, required this.format});

  @override
  List<Object?> get props => [filePath, format];
}

final class ScoreLibraryError extends ScoreLibraryState {
  final String message;

  const ScoreLibraryError({required this.message});

  @override
  List<Object?> get props => [message];
}

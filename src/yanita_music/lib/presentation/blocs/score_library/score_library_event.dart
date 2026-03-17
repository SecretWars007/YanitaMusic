part of 'score_library_bloc.dart';

/// Eventos del BLoC de biblioteca de partituras.
sealed class ScoreLibraryEvent extends Equatable {
  const ScoreLibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar todas las partituras.
final class LoadScores extends ScoreLibraryEvent {}

/// Eliminar una partitura por ID.
final class DeleteScoreEvent extends ScoreLibraryEvent {
  final String scoreId;

  const DeleteScoreEvent({required this.scoreId});

  @override
  List<Object?> get props => [scoreId];
}

/// Exportar partitura como MIDI.
final class ExportScoreAsMidi extends ScoreLibraryEvent {
  final String scoreId;

  const ExportScoreAsMidi({required this.scoreId});

  @override
  List<Object?> get props => [scoreId];
}

/// Exportar partitura como MusicXML.
final class ExportScoreAsMusicXml extends ScoreLibraryEvent {
  final String scoreId;

  const ExportScoreAsMusicXml({required this.scoreId});

  @override
  List<Object?> get props => [scoreId];
}

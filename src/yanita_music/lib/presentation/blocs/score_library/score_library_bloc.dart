import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/domain/usecases/get_scores_usecase.dart';
import 'package:yanita_music/domain/usecases/delete_score_usecase.dart';
import 'package:yanita_music/domain/usecases/export_midi_usecase.dart';
import 'package:yanita_music/domain/usecases/export_musicxml_usecase.dart';
import 'package:yanita_music/core/usecases/usecase.dart';

part 'score_library_event.dart';
part 'score_library_state.dart';

/// BLoC para la biblioteca de partituras almacenadas en SQLite.
class ScoreLibraryBloc extends Bloc<ScoreLibraryEvent, ScoreLibraryState> {
  final GetScoresUseCase _getScoresUseCase;
  final DeleteScoreUseCase _deleteScoreUseCase;
  final ExportMidiUseCase _exportMidiUseCase;
  final ExportMusicXmlUseCase _exportMusicXmlUseCase;

  ScoreLibraryBloc({
    required GetScoresUseCase getScoresUseCase,
    required DeleteScoreUseCase deleteScoreUseCase,
    required ExportMidiUseCase exportMidiUseCase,
    required ExportMusicXmlUseCase exportMusicXmlUseCase,
  }) : _getScoresUseCase = getScoresUseCase,
       _deleteScoreUseCase = deleteScoreUseCase,
       _exportMidiUseCase = exportMidiUseCase,
       _exportMusicXmlUseCase = exportMusicXmlUseCase,
       super(ScoreLibraryInitial()) {
    on<LoadScores>(_onLoadScores);
    on<DeleteScoreEvent>(_onDeleteScore);
    on<ExportScoreAsMidi>(_onExportMidi);
    on<ExportScoreAsMusicXml>(_onExportMusicXml);
  }

  Future<void> _onLoadScores(
    LoadScores event,
    Emitter<ScoreLibraryState> emit,
  ) async {
    emit(ScoreLibraryLoading());

    final result = await _getScoresUseCase(const NoParams());

    await result.fold(
      (failure) async => emit(ScoreLibraryError(message: failure.message)),
      (scores) async {
        // Ordenar por fecha de creación descendente
        final List<Score> finalScores = List.from(scores);
        finalScores.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(ScoreLibraryLoaded(scores: finalScores));
      },
    );
  }

  Future<void> _onDeleteScore(
    DeleteScoreEvent event,
    Emitter<ScoreLibraryState> emit,
  ) async {
    final result = await _deleteScoreUseCase(
      DeleteScoreParams(scoreId: event.scoreId),
    );

    result.fold(
      (failure) => emit(ScoreLibraryError(message: failure.message)),
      (_) => add(LoadScores()), // Reload after delete
    );
  }

  Future<void> _onExportMidi(
    ExportScoreAsMidi event,
    Emitter<ScoreLibraryState> emit,
  ) async {
    final result = await _exportMidiUseCase(
      ExportMidiParams(scoreId: event.scoreId),
    );

    result.fold(
      (failure) => emit(ScoreLibraryError(message: failure.message)),
      (filePath) =>
          emit(ScoreExportSuccess(filePath: filePath, format: 'MIDI')),
    );
  }

  Future<void> _onExportMusicXml(
    ExportScoreAsMusicXml event,
    Emitter<ScoreLibraryState> emit,
  ) async {
    final result = await _exportMusicXmlUseCase(
      ExportMusicXmlParams(scoreId: event.scoreId),
    );

    result.fold(
      (failure) => emit(ScoreLibraryError(message: failure.message)),
      (filePath) =>
          emit(ScoreExportSuccess(filePath: filePath, format: 'MusicXML')),
    );
  }
}

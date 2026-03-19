import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/domain/usecases/get_scores_usecase.dart';
import 'package:yanita_music/domain/usecases/delete_score_usecase.dart';
import 'package:yanita_music/domain/usecases/export_midi_usecase.dart';
import 'package:yanita_music/domain/usecases/export_musicxml_usecase.dart';
import 'package:yanita_music/domain/usecases/save_score_usecase.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/core/utils/demo_score_generator.dart';

part 'score_library_event.dart';
part 'score_library_state.dart';

/// BLoC para la biblioteca de partituras almacenadas en SQLite.
class ScoreLibraryBloc extends Bloc<ScoreLibraryEvent, ScoreLibraryState> {
  final GetScoresUseCase _getScoresUseCase;
  final DeleteScoreUseCase _deleteScoreUseCase;
  final ExportMidiUseCase _exportMidiUseCase;
  final ExportMusicXmlUseCase _exportMusicXmlUseCase;
  final SaveScoreUseCase _saveScoreUseCase;

  ScoreLibraryBloc({
    required GetScoresUseCase getScoresUseCase,
    required DeleteScoreUseCase deleteScoreUseCase,
    required ExportMidiUseCase exportMidiUseCase,
    required ExportMusicXmlUseCase exportMusicXmlUseCase,
    required SaveScoreUseCase saveScoreUseCase,
  }) : _getScoresUseCase = getScoresUseCase,
       _deleteScoreUseCase = deleteScoreUseCase,
       _exportMidiUseCase = exportMidiUseCase,
       _exportMusicXmlUseCase = exportMusicXmlUseCase,
       _saveScoreUseCase = saveScoreUseCase,
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
        final List<Score> finalScores = List.from(scores);

        // Check if demo score exists and needs URL update
        for (int i = 0; i < finalScores.length; i++) {
          final s = finalScores[i];
          if (s.id == 'demo-ode-to-joy' && s.duration < 60.0) {
            final refreshedDemo = DemoScoreGenerator.generateOdeToJoy();
            await _saveScoreUseCase(SaveScoreParams(score: refreshedDemo));
            finalScores[i] = refreshedDemo;
          }
        }

        if (finalScores.isEmpty) {
          // Si no hay partituras, generamos el demo y lo guardamos físicamente en DB
          final demo = DemoScoreGenerator.generateOdeToJoy();
          await _saveScoreUseCase(SaveScoreParams(score: demo));
          emit(ScoreLibraryLoaded(scores: [demo]));
        } else {
          emit(ScoreLibraryLoaded(scores: finalScores));
        }
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

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

        // --- MANTENIMIENTO DE DEMOS ---
        final List<String> demoIds = ['demo-ode-to-joy', 'demo-bare-necessities'];
        
        for (final id in demoIds) {
          final int index = finalScores.indexWhere((s) => s.id == id);
          
          if (index == -1) {
            // Generar y guardar el demo que falta
            final Score newDemo = (id == 'demo-ode-to-joy') 
                ? DemoScoreGenerator.generateOdeToJoy()
                : DemoScoreGenerator.generateTheBareNecessities();
            
            await _saveScoreUseCase(SaveScoreParams(score: newDemo));
            finalScores.add(newDemo);
          } else {
            // Verificar si necesita refrescarse (duración)
            final s = finalScores[index];
            if (s.duration < 60.0) {
              final Score refreshed = (id == 'demo-ode-to-joy')
                  ? DemoScoreGenerator.generateOdeToJoy()
                  : DemoScoreGenerator.generateTheBareNecessities();
              
              await _saveScoreUseCase(SaveScoreParams(score: refreshed));
              finalScores[index] = refreshed;
            }
          }
        }

        // Re-sort para mantener orden cronológico descendente (último creado arriba, o demos abajo)
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

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/domain/usecases/process_audio_usecase.dart';
import 'package:yanita_music/domain/usecases/transcribe_audio_usecase.dart';
import 'package:yanita_music/domain/usecases/save_score_usecase.dart';
import 'package:yanita_music/core/utils/spectrogram_utils.dart';
import 'package:yanita_music/core/utils/logger.dart';


part 'transcription_event.dart';
part 'transcription_state.dart';
part 'transcription_step.dart';

/// BLoC principal para el pipeline de transcripción musical.
class TranscriptionBloc extends Bloc<TranscriptionEvent, TranscriptionState> {
  final ProcessAudioUseCase _processAudioUseCase;
  final TranscribeAudioUseCase _transcribeAudioUseCase;
  final SaveScoreUseCase _saveScoreUseCase;

  static const String _tag = 'TranscriptionBloc';
  String? _lastFilePath;

  TranscriptionBloc({
    required ProcessAudioUseCase processAudioUseCase,
    required TranscribeAudioUseCase transcribeAudioUseCase,
    required SaveScoreUseCase saveScoreUseCase,
  })  : _processAudioUseCase = processAudioUseCase,
        _transcribeAudioUseCase = transcribeAudioUseCase,
        _saveScoreUseCase = saveScoreUseCase,
        super(TranscriptionInitial()) {
    on<SelectAudioFile>(_onSelectAudioFile);
    on<StartTranscription>(_onStartTranscription);
    on<RetryTranscription>(_onRetryTranscription);
    on<ResetTranscription>(_onResetTranscription);
    on<SaveTranscriptionResult>(_onSaveResult);
    on<_UpdateStatus>(_onUpdateStatus);
  }

  static List<TranscriptionStep> _initialSteps() => [
    const TranscriptionStep(id: 'conv', title: 'Conversión (MP3 a WAV)'),
    const TranscriptionStep(id: 'spec', title: 'Generación de Espectrograma'),
    const TranscriptionStep(id: 'inf', title: 'Inferencia de IA'),
    const TranscriptionStep(id: 'xml', title: 'Generación de Partitura'),
  ];

  List<TranscriptionStep> _updateStep(List<TranscriptionStep> steps, String id, TranscriptionStepStatus status, [String? message]) {
    return steps.map((step) => step.id == id ? step.copyWith(status: status, message: message) : step).toList();
  }

  Future<void> _onSelectAudioFile(
    SelectAudioFile event,
    Emitter<TranscriptionState> emit,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'flac'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final filePath = file.path;
      if (filePath != null) {
        _lastFilePath = filePath;
        AppLogger.info('Archivo seleccionado: ${file.name}', tag: _tag);
        emit(AudioFileSelected(
          filePath: filePath,
          fileName: file.name,
        ));
      }
    }
  }

  void _onUpdateStatus(
    _UpdateStatus event,
    Emitter<TranscriptionState> emit,
  ) {
    final currentState = state;
    if (currentState is AudioProcessing) {
      // Mapear mensajes de audio a pasos específicos si es posible
      var updatedSteps = currentState.steps;
      if (event.message.contains('wav')) {
        updatedSteps = _updateStep(updatedSteps, 'conv', TranscriptionStepStatus.processing, event.message);
      } else if (event.message.contains('espectrograma')) {
        updatedSteps = _updateStep(updatedSteps, 'conv', TranscriptionStepStatus.completed);
        updatedSteps = _updateStep(updatedSteps, 'spec', TranscriptionStepStatus.processing, event.message);
      }

      emit(AudioProcessing(
        fileName: currentState.fileName,
        statusMessage: currentState.statusMessage,
        detailMessage: event.message,
        steps: updatedSteps,
      ));
    } else if (currentState is Transcribing) {
      var updatedSteps = currentState.steps;
      updatedSteps = _updateStep(updatedSteps, 'inf', TranscriptionStepStatus.processing, event.message);

      emit(Transcribing(
        fileName: currentState.fileName,
        statusMessage: currentState.statusMessage,
        detailMessage: event.message,
        steps: updatedSteps,
      ));
    }
  }

  Future<void> _onStartTranscription(
    StartTranscription event,
    Emitter<TranscriptionState> emit,
  ) async {
    _lastFilePath = event.filePath;
    final fileName = event.filePath.split('/').last.split('\\').last;

    // Suscribirse a actualizaciones de estado de los repositorios
    final audioStatusSub = _processAudioUseCase.audioRepository.statusStream.listen((message) {
      add(_UpdateStatus(message: message, phase: 'audio'));
    });

    final transcriptionStatusSub = _transcribeAudioUseCase.transcriptionRepository.statusStream.listen((message) {
      add(_UpdateStatus(message: message, phase: 'transcription'));
    });

    AppLogger.info('Iniciando transcripción para: $fileName', tag: _tag);

    try {
      final steps = _initialSteps();
      
      // Fase 1: Procesamiento de audio
      emit(AudioProcessing(
        fileName: fileName,
        statusMessage: 'Preparando espectrograma Mel...',
        steps: _updateStep(steps, 'conv', TranscriptionStepStatus.processing, 'Iniciando decodificación...'),
      ));

      final audioResult = await _processAudioUseCase(
        ProcessAudioParams(filePath: event.filePath),
      );

      final audioFeatures = audioResult.fold(
        (failure) {
          AppLogger.error('Fallo en procesamiento de audio: ${failure.message}', tag: _tag);
          emit(TranscriptionError(
            message: failure.message,
            lastFilePath: event.filePath,
            steps: _updateStep(steps, 'conv', TranscriptionStepStatus.error, failure.message),
          ));
          return null;
        },
        (features) {
          AppLogger.info('Procesamiento de audio completado (Duración: ${features.audioDuration.toStringAsFixed(1)}s)', tag: _tag);
          return features;
        },
      );

      if (audioFeatures == null) return;

      // Fase 2: Transcripción TFLite
      var updatedSteps = _updateStep(steps, 'conv', TranscriptionStepStatus.completed);
      updatedSteps = _updateStep(updatedSteps, 'spec', TranscriptionStepStatus.completed);
      updatedSteps = _updateStep(updatedSteps, 'inf', TranscriptionStepStatus.processing);

      emit(Transcribing(
        fileName: fileName,
        statusMessage: 'Ejecutando modelo Onsets and Frames...',
        steps: updatedSteps,
      ));

      final transcriptionResult = await _transcribeAudioUseCase(
        TranscribeAudioParams(audioFeatures: audioFeatures),
      );

      final noteEvents = transcriptionResult.fold(
        (failure) {
          AppLogger.error('Fallo en inferencia TFLite: ${failure.message}', tag: _tag);
          emit(TranscriptionError(
            message: failure.message,
            lastFilePath: event.filePath,
            steps: _updateStep(updatedSteps, 'inf', TranscriptionStepStatus.error, failure.message),
          ));
          return null;
        },
        (events) {
          AppLogger.info('Inferencia completada: ${events.length} notas detectadas', tag: _tag);
          return events;
        },
      );

      if (noteEvents == null) return;

      // Fase 3: Post-procesamiento y Guardado
      // Detectar polifonía (OPTIMIZADO O(N))
      var maxEndTime = 0.0;
      var isPolyphonic = false;
      for (final note in noteEvents) {
        if (note.startTime < (maxEndTime - 0.01)) { // Margen de 10ms para evitar falsos positivos
          isPolyphonic = true;
          break;
        }
        if (note.endTime > maxEndTime) {
          maxEndTime = note.endTime;
        }
      }

      final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
      
      updatedSteps = _updateStep(updatedSteps, 'inf', TranscriptionStepStatus.completed);
      updatedSteps = _updateStep(updatedSteps, 'xml', TranscriptionStepStatus.processing, 'Analizando polifonía y métrica...');
      
      emit(SavingTranscription(title: title));

      final now = DateTime.now();
      
      // Mover el archivo a un almacenamiento persistente
      String permanentAudioPath = event.filePath;
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final String fileExtension = fileName.split('.').last;
        final String newFileName = '${const Uuid().v4()}.$fileExtension';
        final File newAudioFile = File('${appDocDir.path}/$newFileName');
        
        await File(event.filePath).copy(newAudioFile.path);
        permanentAudioPath = newAudioFile.path;
        AppLogger.debug('Audio persistido en: $permanentAudioPath', tag: _tag);
      } catch (e, stackTrace) {
        AppLogger.error('Error persistiendo audio', tag: _tag, error: e, stackTrace: stackTrace);
        emit(TranscriptionError(
          message: 'Error copiando audio a almacenamiento persistente: $e',
          lastFilePath: event.filePath,
        ));
        return;
      }

      final score = Score(
        id: const Uuid().v4(),
        title: title,
        audioPath: permanentAudioPath,
        noteEvents: noteEvents,
        duration: audioFeatures.audioDuration,
        spectrogramData: SpectrogramUtils.serialize(audioFeatures.melSpectrogram),
        createdAt: now,
        updatedAt: now,
      );


      final saveResult = await _saveScoreUseCase(SaveScoreParams(score: score));

      saveResult.fold(
        (failure) {
          AppLogger.error('Error auto-guardando resultado: ${failure.message}', tag: _tag);
          emit(TranscriptionError(
            message: 'Error al auto-guardar: ${failure.message}',
            lastFilePath: event.filePath,
          ));
        },
        (savedScore) {
          AppLogger.info('Resultado guardado automáticamente con ID: ${savedScore.id}', tag: _tag);
          updatedSteps = _updateStep(updatedSteps, 'xml', TranscriptionStepStatus.completed);
          
          emit(TranscriptionSuccess(
            filePath: event.filePath,
            noteCount: noteEvents.length,
            duration: audioFeatures.audioDuration,
            isPolyphonic: isPolyphonic,
            noteEvents: noteEvents,
          ));
          emit(TranscriptionSaved(
            scoreId: savedScore.id,
            title: savedScore.title,
          ));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error crítico en el pipeline de transcripción', tag: _tag, error: e, stackTrace: stackTrace);
      emit(TranscriptionError(
        message: 'Error inesperado durante la transcripción: $e',
        lastFilePath: event.filePath,
      ));
    } finally {
      audioStatusSub.cancel();
      transcriptionStatusSub.cancel();
    }
  }

  Future<void> _onRetryTranscription(
    RetryTranscription event,
    Emitter<TranscriptionState> emit,
  ) async {
    if (_lastFilePath != null) {
      add(StartTranscription(filePath: _lastFilePath!));
    } else {
      emit(const TranscriptionError(
        message: 'No hay archivo previo para reintentar',
      ));
    }
  }

  void _onResetTranscription(
    ResetTranscription event,
    Emitter<TranscriptionState> emit,
  ) {
    _lastFilePath = null;
    emit(TranscriptionInitial());
  }

  Future<void> _onSaveResult(
    SaveTranscriptionResult event,
    Emitter<TranscriptionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TranscriptionSuccess) return;

    final now = DateTime.now();
    final score = Score(
      id: const Uuid().v4(),
      title: event.title,
      audioPath: currentState.filePath,
      noteEvents: currentState.noteEvents,
      duration: currentState.duration,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _saveScoreUseCase(SaveScoreParams(score: score));

    result.fold(
      (failure) => emit(TranscriptionError(
        message: 'Error guardando partitura: ${failure.message}',
        lastFilePath: currentState.filePath,
      )),
      (savedScore) => emit(TranscriptionSaved(
        scoreId: savedScore.id,
        title: savedScore.title,
      )),
    );
  }
}

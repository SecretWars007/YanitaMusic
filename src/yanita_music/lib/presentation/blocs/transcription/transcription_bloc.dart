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


part 'transcription_event.dart';
part 'transcription_state.dart';

/// BLoC principal para el pipeline de transcripción musical.
class TranscriptionBloc extends Bloc<TranscriptionEvent, TranscriptionState> {
  final ProcessAudioUseCase _processAudioUseCase;
  final TranscribeAudioUseCase _transcribeAudioUseCase;
  final SaveScoreUseCase _saveScoreUseCase;

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
    if (currentState is AudioProcessing && event.phase == 'audio') {
      emit(AudioProcessing(
        fileName: currentState.fileName,
        statusMessage: currentState.statusMessage,
        detailMessage: event.message,
      ));
    } else if (currentState is Transcribing && event.phase == 'transcription') {
      emit(Transcribing(
        fileName: currentState.fileName,
        statusMessage: currentState.statusMessage,
        detailMessage: event.message,
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

    try {
      // Fase 1: Procesamiento de audio
      emit(AudioProcessing(
        fileName: fileName,
        statusMessage: 'Preparando espectrograma Mel...',
      ));

      final audioResult = await _processAudioUseCase(
        ProcessAudioParams(filePath: event.filePath),
      );

      final audioFeatures = audioResult.fold(
        (failure) {
          emit(TranscriptionError(
            message: failure.message,
            lastFilePath: event.filePath,
          ));
          return null;
        },
        (features) => features,
      );

      if (audioFeatures == null) return;

      // Fase 2: Transcripción TFLite
      emit(Transcribing(
        fileName: fileName,
        statusMessage: 'Ejecutando modelo Onsets and Frames...',
      ));

      final transcriptionResult = await _transcribeAudioUseCase(
        TranscribeAudioParams(audioFeatures: audioFeatures),
      );

      final noteEvents = transcriptionResult.fold(
        (failure) {
          emit(TranscriptionError(
            message: failure.message,
            lastFilePath: event.filePath,
          ));
          return null;
        },
        (events) => events,
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
      } catch (e) {
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
        (failure) => emit(TranscriptionError(
          message: 'Error al auto-guardar: ${failure.message}',
          lastFilePath: event.filePath,
        )),
        (savedScore) {
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
    } catch (e) {
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

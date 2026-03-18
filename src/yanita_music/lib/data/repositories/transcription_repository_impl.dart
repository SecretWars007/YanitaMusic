import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/constants/app_constants.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/repositories/transcription_repository.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:logger/logger.dart';

/// Implementación del repositorio de transcripción musical.
///
/// Ejecuta el modelo Onsets and Frames convertido a TFLite
/// para transcribir espectrogramas Mel en eventos de nota.
///
/// Arquitectura del modelo:
/// - Input: Espectrograma Mel [1, frames, 229, 1]
/// - Output Onsets: [1, frames, 88] probabilidad de onset por nota
/// - Output Frames: [1, frames, 88] probabilidad de frame activo por nota
/// - Output Velocity: [1, frames, 88] velocidad estimada
class TranscriptionRepositoryImpl implements TranscriptionRepository {
  Interpreter? _interpreter;
  final Logger _logger = Logger();
  bool _isInitialized = false;

  @override
  Future<Either<Failure, void>> initializeModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;

      // Intentar usar GPU delegate en Android
      // Se captura error silenciosamente si no está disponible
      try {
        if (true) {
          // Platform.isAndroid
          options.addDelegate(GpuDelegateV2());
          _logger.i('GPU delegate habilitado');
        }
      } catch (_) {
        _logger.w('GPU delegate no disponible, usando CPU');
      }

      _interpreter = await Interpreter.fromAsset(
        AppConstants.tfliteModelPath,
        options: options,
      );

      _isInitialized = true;
      _logger.i('Modelo TFLite cargado exitosamente');
      _logger.i('Input tensors: ${_interpreter!.getInputTensors()}');
      _logger.i('Output tensors: ${_interpreter!.getOutputTensors()}');

      return const Right(null);
    } catch (e) {
      _logger.e('Error cargando modelo TFLite: $e');
      return Left(
        ModelLoadFailure(
          message: 'Error al cargar modelo de transcripción: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<NoteEvent>>> transcribe(
    AudioFeatures audioFeatures,
  ) async {
    if (!_isInitialized || _interpreter == null) {
      _logger.i('Modelo no inicializado. Iniciando automáticamente...');
      final initResult = await initializeModel();
      final initError = initResult.fold((failure) => failure, (_) => null);
      if (initError != null) return Left(initError);
    }

    try {
      final noteEvents = await _runInference(audioFeatures);
      _logger.i('Transcripción completada: ${noteEvents.length} notas');
      return Right(noteEvents);
    } on TranscriptionException catch (e) {
      return Left(TranscriptionFailure(message: e.message));
    } on Exception catch (e) {
      return Left(TranscriptionFailure(message: 'Error en transcripción: $e'));
    }
  }

  /// Ejecuta la inferencia del modelo en chunks para gestionar memoria.
  Future<List<NoteEvent>> _runInference(AudioFeatures features) async {
    final numFrames = features.numFrames;
    final numMelBins = features.numMelBins;

    // Preparar input tensor: [1, numFrames, numMelBins, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        numFrames,
        (frame) => List.generate(
          numMelBins,
          (bin) => [features.melSpectrogram[frame][bin]],
        ),
      ),
    );

    // Preparar output tensors
    final onsetOutput = List.generate(
      1,
      (_) => List.generate(
        numFrames,
        (_) => Float32List(AppConstants.numMidiNotes),
      ),
    );

    final frameOutput = List.generate(
      1,
      (_) => List.generate(
        numFrames,
        (_) => Float32List(AppConstants.numMidiNotes),
      ),
    );

    final velocityOutput = List.generate(
      1,
      (_) => List.generate(
        numFrames,
        (_) => Float32List(AppConstants.numMidiNotes),
      ),
    );

    // Ejecutar inferencia
    final outputs = {0: onsetOutput, 1: frameOutput, 2: velocityOutput};

    _interpreter!.runForMultipleInputs([input], outputs);

    // Decodificar outputs a NoteEvents
    return _decodeOutputs(
      onsetOutput[0],
      frameOutput[0],
      velocityOutput[0],
      numFrames,
      features.audioDuration,
    );
  }

  /// Decodifica las salidas del modelo en eventos de nota.
  ///
  /// Implementa el algoritmo de decodificación Onsets and Frames:
  /// 1. Detectar onsets donde la probabilidad supera el threshold
  /// 2. Extender notas mientras el frame esté activo
  /// 3. Asignar velocidad desde la salida de velocidad
  List<NoteEvent> _decodeOutputs(
    List<Float32List> onsets,
    List<Float32List> frames,
    List<Float32List> velocities,
    int numFrames,
    double audioDuration,
  ) {
    final noteEvents = <NoteEvent>[];
    final secondsPerFrame = audioDuration / numFrames;

    // Estado de tracking por cada nota MIDI
    final activeNotes = <int, _ActiveNote>{};

    for (var frame = 0; frame < numFrames; frame++) {
      for (var note = 0; note < AppConstants.numMidiNotes; note++) {
        final midiNote = note + AppConstants.midiNoteMin;
        final onsetProb = onsets[frame][note];
        final frameProb = frames[frame][note];

        // Detectar onset
        if (onsetProb > AppConstants.onsetThreshold) {
          // Si ya hay una nota activa, cerrarla
          if (activeNotes.containsKey(midiNote)) {
            final active = activeNotes[midiNote]!;
            noteEvents.add(
              NoteEvent(
                startTime: active.startFrame * secondsPerFrame,
                endTime: frame * secondsPerFrame,
                midiNote: midiNote,
                velocity: active.velocity,
                confidence: active.maxOnsetProb,
              ),
            );
          }

          // Iniciar nueva nota
          final velocity =
              (velocities[frame][note].clamp(0.0, 1.0) *
                      AppConstants.velocityScale)
                  .round()
                  .clamp(1, 127);

          activeNotes[midiNote] = _ActiveNote(
            startFrame: frame,
            velocity: velocity,
            maxOnsetProb: onsetProb,
          );
        }
        // Verificar si frame sigue activo
        else if (activeNotes.containsKey(midiNote)) {
          if (frameProb < AppConstants.frameThreshold) {
            // Nota terminó
            final active = activeNotes.remove(midiNote)!;
            noteEvents.add(
              NoteEvent(
                startTime: active.startFrame * secondsPerFrame,
                endTime: frame * secondsPerFrame,
                midiNote: midiNote,
                velocity: active.velocity,
                confidence: active.maxOnsetProb,
              ),
            );
          }
        }
      }
    }

    // Cerrar notas que siguen activas al final
    for (final entry in activeNotes.entries) {
      noteEvents.add(
        NoteEvent(
          startTime: entry.value.startFrame * secondsPerFrame,
          endTime: audioDuration,
          midiNote: entry.key,
          velocity: entry.value.velocity,
          confidence: entry.value.maxOnsetProb,
        ),
      );
    }

    // Ordenar por tiempo de inicio
    noteEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return noteEvents;
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    _logger.i('Modelo TFLite liberado');
  }
}

/// Clase auxiliar para tracking de notas activas durante decodificación.
class _ActiveNote {
  final int startFrame;
  final int velocity;
  final double maxOnsetProb;

  _ActiveNote({
    required this.startFrame,
    required this.velocity,
    required this.maxOnsetProb,
  });
}

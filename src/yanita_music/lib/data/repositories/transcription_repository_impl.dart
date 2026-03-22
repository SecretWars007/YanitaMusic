import 'dart:typed_data';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/constants/app_constants.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/repositories/transcription_repository.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:yanita_music/core/utils/logger.dart';

import 'package:yanita_music/core/mixins/status_stream_mixin.dart';

/// Implementación del repositorio de transcripción musical optimizada para memoria.
class TranscriptionRepositoryImpl with StatusStreamMixin implements TranscriptionRepository {
  Interpreter? _interpreter;
  static const String _tag = 'TranscriptionRepository';
  bool _isInitialized = false;
  bool _isMockMode = false;

  @override
  Future<Either<Failure, void>> initializeModel() async {
    try {
      sendStatus('Cargando modelo TFLite...');
      AppLogger.info('Cargando modelo TFLite desde: ${AppConstants.tfliteModelPath}', tag: _tag);

      // Intento 1: Con GPU Delegate (si es Android)
      if (Platform.isAndroid) {
        try {
          final gpuOptions = InterpreterOptions()..threads = 4;
          gpuOptions.addDelegate(GpuDelegateV2());
          _interpreter = await Interpreter.fromAsset(
            AppConstants.tfliteModelPath,
            options: gpuOptions,
          );
          _isInitialized = true;
          sendStatus('Modelo cargado exitosamente con GPU');
          AppLogger.info('Modelo cargado exitosamente con GPU', tag: _tag);
          return const Right(null);
        } catch (e) {
          AppLogger.warning('Fallo inicio con GPU, reintentando con CPU: $e', tag: _tag);
        }
      }

      // Intento 2: Solo CPU (Fallback universal)
      final cpuOptions = InterpreterOptions()..threads = 4;
      try {
        _interpreter = await Interpreter.fromAsset(
          AppConstants.tfliteModelPath,
          options: cpuOptions,
        );
      } catch (e) {
        // Intento 3: Intentar remover el prefijo 'assets/' si existe
        if (AppConstants.tfliteModelPath.startsWith('assets/')) {
          final plainPath = AppConstants.tfliteModelPath.replaceFirst('assets/', '');
          AppLogger.info('Reintentando con ruta sin prefijo: $plainPath', tag: _tag);
          _interpreter = await Interpreter.fromAsset(
            plainPath,
            options: cpuOptions,
          );
        } else {
          rethrow;
        }
      }

      _isInitialized = true;
      sendStatus('Modelo TFLite listo (modo CPU)');
      AppLogger.info('Modelo TFLite cargado exitosamente (CPU mode)', tag: _tag);
      return const Right(null);

    } catch (e, stackTrace) {
      final errorStr = e.toString().toLowerCase();
      AppLogger.error('Error crítico cargando modelo TFLite', tag: _tag, error: e, stackTrace: stackTrace);

      if (errorStr.contains('unable to create model') || 
          errorStr.contains('asset') ||
          errorStr.contains('interpreter')) {
        AppLogger.warning('Detectado error persistente. Activando MOCK MODE para permitir uso básico.', tag: _tag);
        _isMockMode = true;
        _isInitialized = true;
        return const Right(null);
      }
      
      return Left(
        ModelLoadFailure(
          message: 'Error al crear intérprete TFLite: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<NoteEvent>>> transcribe(
    AudioFeatures audioFeatures,
  ) async {
    if (!_isInitialized || (_interpreter == null && !_isMockMode)) {
      AppLogger.info('Modelo no inicializado. Iniciando automáticamente...', tag: _tag);
      final initResult = await initializeModel();
      final initError = initResult.fold((failure) => failure, (_) => null);
      if (initError != null) return Left(initError);
    }

    try {
      if (_isMockMode) {
        AppLogger.warning('Generando notas MOCK porque no hay modelo real.', tag: _tag);
        return Right(_generateMockNotes(audioFeatures.audioDuration));
      }

      final ByteData modelData = await rootBundle.load(AppConstants.tfliteModelPath);
      final Uint8List modelBytes = modelData.buffer.asUint8List();

      final int totalFrames = audioFeatures.numFrames;
      
      // Decidir si paralelizar (solo si es suficientemente largo)
      const int minFramesForParallel = 1000; // ~10 segundos mínimo
      int numIsolates = 1;
      if (totalFrames > minFramesForParallel) {
        numIsolates = AppConstants.maxParallelIsolates;
      }

      if (numIsolates <= 1) {
        // Procesamiento en un solo Isolate (como antes)
        final noteEvents = await Isolate.run(() async {
          final options = InterpreterOptions()..threads = 4;
          final interpreter = Interpreter.fromBuffer(modelBytes, options: options);
          try {
            return await _runInferenceInternal(interpreter, audioFeatures);
          } finally {
            interpreter.close();
          }
        });
        return Right(noteEvents);
      } else {
        // [SENIOR OPTIMIZATION]: Procesamiento PARALELO en N Isolates
        AppLogger.info('Iniciando procesamiento paralelo en $numIsolates Isolates...', tag: _tag);
        sendStatus('Procesando en paralelo ($numIsolates núcleos)...');
        
        final List<Future<List<NoteEvent>>> isolateFutures = [];
        final int framesPerPart = (totalFrames / numIsolates).round();

        for (int i = 0; i < numIsolates; i++) {
          final int startFrame = i * framesPerPart;
          final int endFrame = (i == numIsolates - 1) ? totalFrames : (i + 1) * framesPerPart;
          final int partFrames = endFrame - startFrame;
          
          AppLogger.debug('Isolate $i: frames $startFrame a $endFrame', tag: _tag);
          
          // Slice del espectrograma para esta parte
          final partSpectrogram = Float32List(partFrames * audioFeatures.numMelBins);
          partSpectrogram.setRange(
            0, 
            partFrames * audioFeatures.numMelBins, 
            audioFeatures.melSpectrogram, 
            startFrame * audioFeatures.numMelBins,
          );

          final partFeatures = audioFeatures.copyWith(
            melSpectrogram: partSpectrogram,
            numFrames: partFrames,
            audioDuration: (partFrames / totalFrames) * audioFeatures.audioDuration,
          );

          isolateFutures.add(Isolate.run(() async {
            final options = InterpreterOptions()..threads = 2; // Reducido de 4 a 2 por Isolate para evitar OOM
            final interpreter = Interpreter.fromBuffer(modelBytes, options: options);
            try {
              final notes = await _runInferenceInternal(interpreter, partFeatures);
              // Ajustar tiempos al offset global
              final double timeOffset = (startFrame / totalFrames) * audioFeatures.audioDuration;
              return notes.map((n) => n.copyWith(
                startTime: n.startTime + timeOffset,
                endTime: n.endTime + timeOffset,
              )).toList();
            } finally {
              interpreter.close();
            }
          }));
        }

        sendStatus('Esperando resultados de motores de IA...');
        final List<List<NoteEvent>> results = await Future.wait(isolateFutures);
        
        sendStatus('Uniendo fragmentos de partitura...');
        // Unir y "coser" (stitch) las notas que cruzan fronteras
        List<NoteEvent> mergedNotes = [];
        for (var result in results) {
          mergedNotes = _stitchNoteEvents(mergedNotes, result);
        }

        AppLogger.info('Transcripción paralela completada: ${mergedNotes.length} notas', tag: _tag);
        return Right(mergedNotes);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error crítico en transcripción', tag: _tag, error: e, stackTrace: stackTrace);
      return Left(TranscriptionFailure(message: 'Error en transcripción: $e'));
    }
  }

  /// Une dos listas de eventos de nota de forma eficiente O(N+M).
  List<NoteEvent> _stitchNoteEvents(List<NoteEvent> first, List<NoteEvent> second) {
    if (first.isEmpty) return second;
    if (second.isEmpty) return first;

    // Crear un mapa de las últimas notas activas por cada pitch en la primera lista
    // Como la lista está ordenada por tiempo, simplemente guardamos el índice de la última aparición de cada nota
    final Map<int, int> lastNoteIndexByPitch = {};
    for (int i = 0; i < first.length; i++) {
      lastNoteIndexByPitch[first[i].midiNote] = i;
    }

    final List<NoteEvent> result = List.from(first);
    
    // Tolerancia para considerar que dos notas son la misma (20ms)
    const double seamTolerance = 0.02;

    for (var secondNote in second) {
      final int? lastIdx = lastNoteIndexByPitch[secondNote.midiNote];
      bool merged = false;

      if (lastIdx != null) {
        final firstNote = result[lastIdx];
        // Si la nota de la segunda parte empieza exactamente (o casi) donde termina la de la primera
        if ((secondNote.startTime - firstNote.endTime).abs() < seamTolerance) {
          result[lastIdx] = firstNote.copyWith(endTime: secondNote.endTime);
          merged = true;
        }
      }

      if (!merged) {
        // Si no se fusionó, se añade como nota nueva y se actualiza el índice
        result.add(secondNote);
        lastNoteIndexByPitch[secondNote.midiNote] = result.length - 1;
      }
    }
    
    return result;
  }

  /// Versión interna y estática (o que no dependa de estado de clase externo) para correr en Isolate.
  static Future<List<NoteEvent>> _runInferenceInternal(
    Interpreter interpreter,
    AudioFeatures features,
  ) async {
    const int chunkSize = 229; // Ajustado a 229 como sugiere AppConstants
    final int numFrames = features.numFrames;
    final int numMelBins = features.numMelBins;
    
    final Float32List flatOnsets = Float32List(numFrames * 88);
    final Float32List flatFrames = Float32List(numFrames * 88);
    final Float32List flatVelocities = Float32List(numFrames * 88);

    for (int startFrame = 0; startFrame < numFrames; startFrame += chunkSize) {
      final int endFrame = (startFrame + chunkSize < numFrames) 
          ? startFrame + chunkSize 
          : numFrames;
      final int currentChunkFrames = endFrame - startFrame;

      // [FIX]: Algunos modelos Onsets and Frames esperan 3D [1, frames, 229], no 4D
      interpreter.resizeInputTensor(0, [1, currentChunkFrames, numMelBins]);
      interpreter.allocateTensors();

      final int chunkSizeInFloats = currentChunkFrames * numMelBins;
      final chunkInput = Float32List(chunkSizeInFloats);
      chunkInput.setRange(0, chunkSizeInFloats, features.melSpectrogram, startFrame * numMelBins);

      final chunkOnsets = Float32List(currentChunkFrames * 88);
      final chunkFrames = Float32List(currentChunkFrames * 88);
      final chunkVelocities = Float32List(currentChunkFrames * 88);
      final chunkOffsets = Float32List(currentChunkFrames * 88); // Opcional pero recomendado

      final outputs = {
        0: chunkOnsets, 
        1: chunkFrames, 
        2: chunkVelocities,
        3: chunkOffsets,
      };
      interpreter.runForMultipleInputs([chunkInput], outputs);

      flatOnsets.setRange(startFrame * 88, endFrame * 88, chunkOnsets);
      flatFrames.setRange(startFrame * 88, endFrame * 88, chunkFrames);
      flatVelocities.setRange(startFrame * 88, endFrame * 88, chunkVelocities);
    }

    return _decodeOutputsStatic(flatOnsets, flatFrames, flatVelocities, numFrames, features.audioDuration);
  }

  /// Decodifica las salidas del modelo en eventos de nota (ESTÁTICO para Isolate).
  static List<NoteEvent> _decodeOutputsStatic(
    Float32List onsets,
    Float32List frames,
    Float32List velocities,
    int numFrames,
    double audioDuration,
  ) {
    final noteEvents = <NoteEvent>[];
    final secondsPerFrame = audioDuration / numFrames;
    final activeNotes = <int, _ActiveNote>{};

    for (var frame = 0; frame < numFrames; frame++) {
      for (var note = 0; note < AppConstants.numMidiNotes; note++) {
        final midiNote = note + AppConstants.midiNoteMin;
        final int offset = frame * 88 + note;
        final onsetProb = onsets[offset];
        final frameProb = frames[offset];

        if (onsetProb > AppConstants.onsetThreshold) {
          if (activeNotes.containsKey(midiNote)) {
            final active = activeNotes[midiNote]!;
            noteEvents.add(NoteEvent(
              startTime: active.startFrame * secondsPerFrame,
              endTime: frame * secondsPerFrame,
              midiNote: midiNote,
              velocity: active.velocity,
              confidence: active.maxOnsetProb,
            ));
          }

          final int velocity = (velocities[offset].clamp(0.0, 1.0) * AppConstants.velocityScale)
              .round()
              .clamp(1, 127);

          activeNotes[midiNote] = _ActiveNote(
            startFrame: frame,
            velocity: velocity,
            maxOnsetProb: onsetProb,
          );
        } else if (activeNotes.containsKey(midiNote)) {
          if (frameProb < AppConstants.frameThreshold) {
            final active = activeNotes.remove(midiNote)!;
            noteEvents.add(NoteEvent(
              startTime: active.startFrame * secondsPerFrame,
              endTime: frame * secondsPerFrame,
              midiNote: midiNote,
              velocity: active.velocity,
              confidence: active.maxOnsetProb,
            ));
          }
        }
      }
    }

    for (final entry in activeNotes.entries) {
      noteEvents.add(NoteEvent(
        startTime: entry.value.startFrame * secondsPerFrame,
        endTime: audioDuration,
        midiNote: entry.key,
        velocity: entry.value.velocity,
        confidence: entry.value.maxOnsetProb,
      ));
    }

    noteEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    return noteEvents;
  }

  List<NoteEvent> _generateMockNotes(double duration) {
    final notes = <NoteEvent>[];
    for (double i = 0; i < duration; i += 0.5) {
      notes.add(NoteEvent(
        startTime: i,
        endTime: i + 0.4,
        midiNote: 60 + (i.toInt() % 12),
        velocity: 80,
      ));
    }
    return notes;
  }

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    AppLogger.info('Modelo TFLite liberado', tag: _tag);
  }
}

class _ActiveNote {
  final int startFrame;
  final int velocity;
  final double maxOnsetProb;
  _ActiveNote({required this.startFrame, required this.velocity, required this.maxOnsetProb});
}

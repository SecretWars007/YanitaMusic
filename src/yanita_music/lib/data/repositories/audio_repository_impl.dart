import 'dart:isolate';
import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/security/file_validator.dart';
import 'package:yanita_music/core/utils/audio_converter.dart';
import 'package:yanita_music/data/datasources/native/audio_processor_ffi.dart';

import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/repositories/audio_repository.dart';

import 'package:yanita_music/core/mixins/status_stream_mixin.dart';

/// Implementación del repositorio de audio.
class AudioRepositoryImpl with StatusStreamMixin implements AudioRepository {
  final FileValidator _fileValidator;
  final AudioConverter _audioConverter;

  AudioRepositoryImpl({
    required FileValidator fileValidator,
    AudioConverter audioConverter = const AudioConverter(),
  })  : _fileValidator = fileValidator,
        _audioConverter = audioConverter;


  @override
  Future<Either<Failure, AudioFeatures>> processAudioFile(
    String filePath,
  ) async {
    try {
      // 1. Validar archivo
      sendStatus('Validando archivo de audio...');
      final checksum = await _fileValidator.validateAudioFile(filePath);

      // 2. Convertir a WAV (16kHz, mono) usando FFmpeg
      // Esto asegura compatibilidad total con el procesador nativo.
      sendStatus('Convirtiendo audio a WAV profesional (FFmpeg)...');
      final wavPath = await _audioConverter.convertToWav(filePath);

      try {
        // 3. Procesar WAV con módulo C++ FFI
        sendStatus('Analizando espectro Mel (C++ FFI)...');
        
        final result = await Isolate.run(() {
          final processor = AudioProcessorFFI();
          processor.initialize();
          return processor.processFile(wavPath);
        });

        // 4. Convertir record nativo a entidad de dominio
        final features = AudioFeatures(
          melSpectrogram: result.spectrogram,
          numFrames: result.numFrames,
          numMelBins: result.numMelBins,
          audioDuration: result.duration,
          sampleRate: 16000,
          sourceChecksum: checksum,
        );

        return Right(features);
      } finally {
        // Limpiar archivo temporal generado por FFmpeg
        _audioConverter.cleanTempFile(wavPath);
      }

    } on FileValidationException catch (e) {

      return Left(FileValidationFailure(message: e.message));
    } on AudioProcessingException catch (e) {
      return Left(AudioProcessingFailure(message: e.message));
    } on Exception catch (e) {
      return Left(AudioProcessingFailure(
        message: 'Error inesperado al procesar audio: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, AudioFeatures>> processAudioBuffer(
    List<int> audioBytes,
  ) async {
    // Pendiente: Implementar procesamiento desde buffer de bytes
    // cuando se integre la captura en vivo de audio.
    return const Left(AudioProcessingFailure(
      message: 'Procesamiento desde buffer aún no implementado',
    ));
  }
}

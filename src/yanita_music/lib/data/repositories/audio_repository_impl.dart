import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/security/file_validator.dart';
import 'package:yanita_music/data/datasources/native/audio_processor_ffi.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/repositories/audio_repository.dart';

/// Implementación del repositorio de audio.
///
/// Orquesta la validación de archivos y el procesamiento
/// nativo de audio via C++ FFI, convirtiendo los datos
/// nativos en la entidad [AudioFeatures] del dominio.
class AudioRepositoryImpl implements AudioRepository {
  final AudioProcessorFFI _audioProcessorFFI;
  final FileValidator _fileValidator;

  AudioRepositoryImpl({
    required AudioProcessorFFI audioProcessorFFI,
    required FileValidator fileValidator,
  })  : _audioProcessorFFI = audioProcessorFFI,
        _fileValidator = fileValidator;

  @override
  Future<Either<Failure, AudioFeatures>> processAudioFile(
    String filePath,
  ) async {
    try {
      // Validar archivo
      final checksum = await _fileValidator.validateAudioFile(filePath);

      // Procesar con módulo C++ FFI
      final result = _audioProcessorFFI.processFile(filePath);

      // Convertir record nativo a entidad de dominio
      final features = AudioFeatures(
        melSpectrogram: result.spectrogram,
        numFrames: result.numFrames,
        numMelBins: result.numMelBins,
        audioDuration: result.duration,
        sampleRate: 16000,
        sourceChecksum: checksum,
      );

      return Right(features);
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

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/security/file_validator.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/repositories/audio_repository.dart';

/// Caso de uso: Procesar archivo de audio.
///
/// Valida el archivo y ejecuta el pipeline de preprocesamiento DSP
/// para generar el espectrograma Mel necesario para la transcripción.
class ProcessAudioUseCase extends UseCase<AudioFeatures, ProcessAudioParams> {
  final AudioRepository audioRepository;
  final FileValidator _fileValidator;

  ProcessAudioUseCase({
    required this.audioRepository,
    required FileValidator fileValidator,
  }) : _fileValidator = fileValidator;

  @override
  Future<Either<Failure, AudioFeatures>> call(ProcessAudioParams params) async {
    try {
      // Validación de seguridad del archivo
      await _fileValidator.validateAudioFile(params.filePath);

      // Procesamiento DSP via C++ FFI
      return await audioRepository.processAudioFile(params.filePath);
    } on Exception catch (e) {
      return Left(
        AudioProcessingFailure(message: 'Error procesando audio: $e'),
      );
    }
  }
}

class ProcessAudioParams extends Equatable {
  final String filePath;

  const ProcessAudioParams({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

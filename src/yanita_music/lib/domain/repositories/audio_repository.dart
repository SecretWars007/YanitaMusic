import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';

/// Contrato del repositorio de procesamiento de audio.
///
/// Define la interfaz que la capa de datos debe implementar
/// para el pipeline de preprocesamiento DSP via C++ FFI.
abstract class AudioRepository {
  /// Stream de estados en tiempo real.
  Stream<String> get statusStream;

  /// Procesa un archivo MP3 y genera el espectrograma Mel.
  ///
  /// [filePath] Ruta al archivo de audio validado.
  /// Retorna [AudioFeatures] con el espectrograma listo para inferencia.
  Future<Either<Failure, AudioFeatures>> processAudioFile(String filePath);

  /// Procesa audio desde un buffer de bytes en memoria.
  Future<Either<Failure, AudioFeatures>> processAudioBuffer(
    List<int> audioBytes,
  );
}

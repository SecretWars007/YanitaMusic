import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/entities/note_event.dart';

/// Contrato del repositorio de transcripción musical.
///
/// Encapsula la lógica de inferencia TFLite con el modelo
/// Onsets and Frames para transcripción AMT.
abstract class TranscriptionRepository {
  /// Inicializa el modelo TFLite. Debe llamarse una vez al inicio.
  Future<Either<Failure, void>> initializeModel();

  /// Ejecuta la transcripción sobre features espectrales.
  ///
  /// Retorna una lista de [NoteEvent] detectados.
  Future<Either<Failure, List<NoteEvent>>> transcribe(
    AudioFeatures audioFeatures,
  );

  /// Libera recursos del modelo.
  Future<void> dispose();
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/repositories/transcription_repository.dart';

/// Caso de uso: Transcribir audio a eventos musicales.
///
/// Ejecuta la inferencia del modelo Onsets and Frames sobre
/// el espectrograma Mel para detectar notas de piano.
class TranscribeAudioUseCase
    extends UseCase<List<NoteEvent>, TranscribeAudioParams> {
  final TranscriptionRepository transcriptionRepository;

  TranscribeAudioUseCase({
    required this.transcriptionRepository,
  });

  @override
  Future<Either<Failure, List<NoteEvent>>> call(
    TranscribeAudioParams params,
  ) async {
    return await transcriptionRepository.transcribe(params.audioFeatures);
  }
}

class TranscribeAudioParams extends Equatable {
  final AudioFeatures audioFeatures;

  const TranscribeAudioParams({required this.audioFeatures});

  @override
  List<Object?> get props => [audioFeatures];
}

part of 'transcription_bloc.dart';

/// Eventos del BLoC de transcripción musical.
sealed class TranscriptionEvent extends Equatable {
  const TranscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Seleccionar archivo MP3 para transcripción.
final class SelectAudioFile extends TranscriptionEvent {}

/// Iniciar el pipeline completo de transcripción.
final class StartTranscription extends TranscriptionEvent {
  final String filePath;

  const StartTranscription({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// Reintentar transcripción tras un error.
final class RetryTranscription extends TranscriptionEvent {}

/// Resetear el estado a inicial.
final class ResetTranscription extends TranscriptionEvent {}

/// Guardar la partitura transcrita.
final class SaveTranscriptionResult extends TranscriptionEvent {
  final String title;

  const SaveTranscriptionResult({required this.title});

  @override
  List<Object?> get props => [title];
}

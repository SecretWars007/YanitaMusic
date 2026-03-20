part of 'transcription_bloc.dart';

/// Eventos del BLoC de transcripción musical.
sealed class TranscriptionEvent extends Equatable {
  const TranscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Seleccionar archivo MP3 para transcripción.
final class SelectAudioFile extends TranscriptionEvent {
  final String? filePath;
  const SelectAudioFile({this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// Evento interno para actualizar el mensaje de estado en tiempo real.
class _UpdateStatus extends TranscriptionEvent {
  final String message;
  final String phase; // 'audio' o 'transcription'
  const _UpdateStatus({required this.message, required this.phase});

  @override
  List<Object?> get props => [message, phase];
}

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

part of 'transcription_bloc.dart';

/// Estados del BLoC de transcripción musical.
sealed class TranscriptionState extends Equatable {
  const TranscriptionState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial – esperando selección de archivo.
final class TranscriptionInitial extends TranscriptionState {}

/// Archivo seleccionado, listo para procesar.
final class AudioFileSelected extends TranscriptionState {
  final String filePath;
  final String fileName;

  const AudioFileSelected({
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [filePath, fileName];
}

/// Procesando audio (generando espectrograma Mel via C++ FFI).
final class AudioProcessing extends TranscriptionState {
  final String fileName;
  final String statusMessage;
  final String? detailMessage;
  final List<TranscriptionStep> steps;

  const AudioProcessing({
    required this.fileName,
    required this.steps,
    this.statusMessage = 'Procesando audio...',
    this.detailMessage,
  });

  @override
  List<Object?> get props => [fileName, statusMessage, detailMessage, steps];
}

/// Transcribiendo (inferencia TFLite del modelo Onsets and Frames).
final class Transcribing extends TranscriptionState {
  final String fileName;
  final String statusMessage;
  final String? detailMessage;
  final List<TranscriptionStep> steps;

  const Transcribing({
    required this.fileName,
    required this.steps,
    this.statusMessage = 'Transcribiendo notas musicales...',
    this.detailMessage,
  });

  @override
  List<Object?> get props => [fileName, statusMessage, detailMessage, steps];
}

/// Transcripción completada exitosamente.
final class TranscriptionSuccess extends TranscriptionState {
  final String filePath;
  final int noteCount;
  final double duration;
  final bool isPolyphonic;
  final List<NoteEvent> noteEvents;

  const TranscriptionSuccess({
    required this.filePath,
    required this.noteCount,
    required this.duration,
    required this.isPolyphonic,
    required this.noteEvents,
  });

  @override
  List<Object?> get props => [filePath, noteCount, duration];
}

/// Guardando la partitura en la base de datos de forma automática.
final class SavingTranscription extends TranscriptionState {
  final String title;

  const SavingTranscription({required this.title});

  @override
  List<Object?> get props => [title];
}

/// Partitura guardada en base de datos.
final class TranscriptionSaved extends TranscriptionState {
  final String scoreId;
  final String title;

  const TranscriptionSaved({
    required this.scoreId,
    required this.title,
  });

  @override
  List<Object?> get props => [scoreId, title];
}

/// Error durante cualquier fase del pipeline.
final class TranscriptionError extends TranscriptionState {
  final String message;
  final String? lastFilePath;
  final List<TranscriptionStep>? steps;

  const TranscriptionError({
    required this.message,
    this.lastFilePath,
    this.steps,
  });

  @override
  List<Object?> get props => [message, lastFilePath, steps];
}

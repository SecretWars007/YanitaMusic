part of 'transcription_bloc.dart';

enum TranscriptionStepStatus { pending, processing, completed, error }

class TranscriptionStep extends Equatable {
  final String id;
  final String title;
  final TranscriptionStepStatus status;
  final String? message;

  const TranscriptionStep({
    required this.id,
    required this.title,
    this.status = TranscriptionStepStatus.pending,
    this.message,
  });

  TranscriptionStep copyWith({
    TranscriptionStepStatus? status,
    String? message,
  }) {
    return TranscriptionStep(
      id: id,
      title: title,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [id, title, status, message];
}

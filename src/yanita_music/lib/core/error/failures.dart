import 'package:equatable/equatable.dart';

/// Jerarquía de Failures para manejo de errores funcional.
///
/// Sigue el patrón `Either<Failure, Success>` de clean architecture
/// para separar errores del dominio de excepciones técnicas.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class AudioProcessingFailure extends Failure {
  const AudioProcessingFailure({required super.message, super.code});
}

class TranscriptionFailure extends Failure {
  const TranscriptionFailure({required super.message, super.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code});
}

class FileValidationFailure extends Failure {
  const FileValidationFailure({required super.message, super.code});
}

class SecurityFailure extends Failure {
  const SecurityFailure({required super.message, super.code});
}

class ModelLoadFailure extends Failure {
  const ModelLoadFailure({required super.message, super.code});
}

class ExportFailure extends Failure {
  const ExportFailure({required super.message, super.code});
}

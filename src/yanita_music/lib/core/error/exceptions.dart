/// Excepciones de la capa de datos.
///
/// Se mapean a Failures en la capa de repositorio para mantener
/// la separación de responsabilidades de clean architecture.
class AudioProcessingException implements Exception {
  final String message;
  const AudioProcessingException({required this.message});

  @override
  String toString() => 'AudioProcessingException: $message';
}

class TranscriptionException implements Exception {
  final String message;
  const TranscriptionException(this.message);

  @override
  String toString() => 'TranscriptionException: $message';
}

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

class FileValidationException implements Exception {
  final String message;
  const FileValidationException(this.message);

  @override
  String toString() => 'FileValidationException: $message';
}

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

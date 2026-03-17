import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:yanita_music/core/constants/app_constants.dart';
import 'package:yanita_music/core/error/exceptions.dart';

/// Validador de archivos de audio con buenas prácticas de seguridad SDLC.
///
/// Verifica extensión, tamaño, existencia y genera checksums SHA-256
/// para garantizar integridad y trazabilidad de los archivos procesados.
///
/// Usa métodos **sincrónicos** de `dart:io` para cumplir con la regla
/// `avoid_slow_async_io` del linter, evitando I/O asíncrono innecesario
/// en operaciones rápidas de metadatos de archivo.
class FileValidator {
  const FileValidator();

  /// Valida un archivo de audio y retorna su checksum SHA-256.
  ///
  /// Lanza [FileValidationException] si el archivo no es válido.
  /// Retorna el hash SHA-256 hex string del archivo.
  Future<String> validateAudioFile(String filePath) async {
    // 1. Validar que la ruta no esté vacía
    if (filePath.trim().isEmpty) {
      throw const FileValidationException(
        'La ruta del archivo no puede estar vacía',
      );
    }

    // 2. Verificar existencia (sincrónico para evitar avoid_slow_async_io)
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileValidationException('El archivo no existe: $filePath');
    }

    // 3. Validar extensión permitida
    final extension = filePath.toLowerCase().split('.').last;
    final dotExtension = '.$extension';
    if (!AppConstants.allowedAudioExtensions.contains(dotExtension)) {
      throw FileValidationException(
        'Formato no soportado: .$extension. '
        'Formatos válidos: ${AppConstants.allowedAudioExtensions.join(", ")}',
      );
    }

    // 4. Validar tamaño (sincrónico)
    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      throw const FileValidationException('El archivo está vacío');
    }
    if (fileSize > AppConstants.maxFileSizeBytes) {
      const maxMb = AppConstants.maxFileSizeBytes / (1024 * 1024);
      throw FileValidationException(
        'El archivo excede el tamaño máximo de ${maxMb.toStringAsFixed(0)} MB',
      );
    }

    // 5. Calcular checksum SHA-256 para trazabilidad
    final checksum = await _computeChecksum(file);

    return checksum;
  }

  /// Calcula el hash SHA-256 del archivo de forma eficiente en chunks.
  Future<String> _computeChecksum(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Validación rápida de extensión sin acceso a disco.
  bool isAllowedExtension(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return AppConstants.allowedAudioExtensions.contains('.$extension');
  }

  /// Validación rápida de que el archivo existe (sincrónica).
  bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }
}

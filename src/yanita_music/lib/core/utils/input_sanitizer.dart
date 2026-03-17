/// Sanitizador de entradas del usuario.
///
/// Previene inyección SQL y XSS en datos ingresados por el usuario
/// antes de persistirlos en SQLite.
class InputSanitizer {
  InputSanitizer._();

  /// Sanitiza texto genérico removiendo caracteres peligrosos.
  static String sanitizeText(String input) {
    // Trim whitespace
    var sanitized = input.trim();

    // Remover caracteres de control excepto newline y tab
    sanitized = sanitized.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
      '',
    );

    // Escapar comillas simples para prevenir SQL injection
    sanitized = sanitized.replaceAll("'", "''");

    // Limitar longitud razonable
    if (sanitized.length > 500) {
      sanitized = sanitized.substring(0, 500);
    }

    return sanitized;
  }

  /// Sanitiza un título de canción o partitura.
  static String sanitizeTitle(String input) {
    var sanitized = sanitizeText(input);

    // Solo permitir alfanuméricos, espacios, guiones y puntos
    sanitized = sanitized.replaceAll(
      RegExp(r'[^\w\s\-\.\,\(\)\áéíóúÁÉÍÓÚñÑüÜ]'),
      '',
    );

    if (sanitized.isEmpty) {
      sanitized = 'Sin título';
    }

    return sanitized;
  }

  /// Valida que una cadena no contenga patrones de inyección SQL.
  static bool isSafeForQuery(String input) {
    final dangerousPatterns = [
      RegExp(r';\s*DROP', caseSensitive: false),
      RegExp(r';\s*DELETE', caseSensitive: false),
      RegExp(r';\s*INSERT', caseSensitive: false),
      RegExp(r';\s*UPDATE', caseSensitive: false),
      RegExp(r'UNION\s+SELECT', caseSensitive: false),
      RegExp(r'--'),
      RegExp(r'/\*'),
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) return false;
    }
    return true;
  }
}

import 'dart:convert';
import 'dart:typed_data';

/// Utilidad para manejar la persistencia de datos de espectrogramas.
/// 
/// Permite convertir Float32List a Base64 y viceversa para 
/// almacenamiento eficiente en SQLite.
class SpectrogramUtils {
  const SpectrogramUtils._();

  /// Serializa un Float32List a una cadena Base64.
  static String serialize(Float32List data) {
    if (data.isEmpty) return '';
    // Convertir la vista de bytes del Float32List directamente a Base64
    final bytes = data.buffer.asUint8List();
    return base64Encode(bytes);
  }

  /// Deserializa una cadena Base64 a un Float32List.
  static Float32List deserialize(String base64Data) {
    if (base64Data.isEmpty) return Float32List(0);
    final bytes = base64Decode(base64Data);
    return bytes.buffer.asFloat32List();
  }
}

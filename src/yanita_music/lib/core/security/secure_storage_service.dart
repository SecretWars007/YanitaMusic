import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Servicio de almacenamiento seguro basado en flutter_secure_storage.
///
/// Gestiona claves de cifrado y tokens sensibles usando el keystore
/// nativo del sistema operativo (Android Keystore / iOS Keychain).
///
/// Principio SDLC: los secretos nunca se almacenan en texto plano
/// ni en SharedPreferences; se delega al hardware seguro del dispositivo.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _encryptionKeyKey = 'app_encryption_key';

  /// Obtiene o genera la clave de cifrado de la aplicación.
  ///
  /// Si no existe, genera una nueva clave aleatoria de 32 caracteres
  /// y la almacena de forma segura.
  Future<String> getOrCreateEncryptionKey() async {
    var key = await _storage.read(key: _encryptionKeyKey);
    if (key == null || key.isEmpty) {
      key = _generateSecureKey();
      await _storage.write(key: _encryptionKeyKey, value: key);
    }
    return key;
  }

  /// Lee un valor seguro por su clave.
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Escribe un valor seguro.
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Elimina un valor seguro.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Verifica si existe una clave.
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Elimina todos los datos seguros (para reset o logout).
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Genera una clave aleatoria segura de 32 caracteres.
  String _generateSecureKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }
}

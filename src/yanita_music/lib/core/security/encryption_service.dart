import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'dart:math';

/// Servicio de cifrado AES-256-CBC para datos sensibles.
///
/// Implementa cifrado simétrico para proteger datos almacenados
/// en SQLite, cumpliendo con buenas prácticas SDLC de seguridad
/// de datos en reposo (data-at-rest encryption).
class EncryptionService {
  late final Uint8List _key;
  final Random _secureRandom = Random.secure();

  EncryptionService({required String encryptionKey}) {
    // Derivar clave de 256 bits desde la key proporcionada
    final keyBytes = utf8.encode(encryptionKey);
    final digest = Digest('SHA-256');
    _key = digest.process(Uint8List.fromList(keyBytes));
  }

  /// Cifra un texto plano con AES-256-CBC.
  ///
  /// Genera un IV aleatorio de 16 bytes por cada operación
  /// para garantizar que el mismo texto produce distintos cifrados.
  /// Retorna base64(IV + ciphertext).
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    final iv = _generateIV();
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    cipher.init(
      true,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(_key), iv),
        null,
      ),
    );

    final input = Uint8List.fromList(utf8.encode(plainText));
    final encrypted = cipher.process(input);

    // Prepend IV al ciphertext para descifrado posterior
    final result = Uint8List(iv.length + encrypted.length);
    result.setAll(0, iv);
    result.setAll(iv.length, encrypted);

    return base64Encode(result);
  }

  /// Descifra un texto cifrado con AES-256-CBC.
  ///
  /// Extrae el IV de los primeros 16 bytes del input base64.
  String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    final data = base64Decode(encryptedText);
    final iv = data.sublist(0, 16);
    final cipherText = data.sublist(16);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );

    cipher.init(
      false,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(_key), iv),
        null,
      ),
    );

    final decrypted = cipher.process(Uint8List.fromList(cipherText));
    return utf8.decode(decrypted);
  }

  /// Genera un vector de inicialización criptográficamente seguro.
  Uint8List _generateIV() {
    final iv = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      iv[i] = _secureRandom.nextInt(256);
    }
    return iv;
  }
}

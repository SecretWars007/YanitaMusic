import 'dart:io';
import 'dart:typed_data';

import '../error/exceptions.dart';
import 'logger.dart';

/// Decodificador de audio MP3/WAV a PCM float samples.
/// Para MVP usa decodificación WAV nativa.
/// Para MP3 se integra con el módulo C++ FFI.
class AudioDecoder {
  AudioDecoder();

  /// Carga y decodifica un archivo de audio a samples PCM [-1.0, 1.0].
  Future<AudioSamples> decode(String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw AudioProcessingException(
        message: 'Archivo no encontrado: $filePath',
      );
    }

    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'wav':
        return _decodeWav(file);
      case 'mp3':
        return _decodeMp3(file);
      default:
        throw AudioProcessingException(
          message: 'Formato no soportado: $extension',
        );
    }
  }

  /// Decodifica WAV PCM de 16 bits.
  Future<AudioSamples> _decodeWav(File file) async {
    AppLogger.info('Decodificando WAV: ${file.path}', tag: 'AUDIO');

    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(bytes);

    // Validar RIFF header
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    if (riff != 'RIFF') {
      throw const AudioProcessingException(message: 'Header RIFF inválido');
    }

    final numChannels = data.getUint16(22, Endian.little);
    final sampleRate = data.getUint32(24, Endian.little);
    final bitsPerSample = data.getUint16(34, Endian.little);

    // Buscar chunk "data"
    var dataOffset = 12;
    var dataSize = 0;

    while (dataOffset < bytes.length - 8) {
      final chunkId = String.fromCharCodes(
        bytes.sublist(dataOffset, dataOffset + 4),
      );
      final chunkSize = data.getUint32(dataOffset + 4, Endian.little);

      if (chunkId == 'data') {
        dataOffset += 8;
        dataSize = chunkSize;
        break;
      }
      dataOffset += 8 + chunkSize;
    }

    if (dataSize == 0) {
      throw const AudioProcessingException(message: 'Chunk data no encontrado');
    }

    // Convertir a float mono
    final bytesPerSample = bitsPerSample ~/ 8;
    final totalSamples = dataSize ~/ (bytesPerSample * numChannels);
    final samples = Float64List(totalSamples);

    for (var i = 0; i < totalSamples; i++) {
      var sampleValue = 0.0;

      for (var ch = 0; ch < numChannels; ch++) {
        final offset = dataOffset + (i * numChannels + ch) * bytesPerSample;

        if (offset + bytesPerSample > bytes.length) break;

        if (bitsPerSample == 16) {
          final raw = data.getInt16(offset, Endian.little);
          sampleValue += raw / 32768.0;
        } else if (bitsPerSample == 24) {
          final b0 = bytes[offset];
          final b1 = bytes[offset + 1];
          final b2 = bytes[offset + 2];
          var raw = (b2 << 16) | (b1 << 8) | b0;
          if (raw >= 0x800000) raw -= 0x1000000;
          sampleValue += raw / 8388608.0;
        }
      }

      samples[i] = (sampleValue / numChannels).clamp(-1.0, 1.0);
    }

    AppLogger.info(
      'WAV decodificado: $totalSamples samples, ${sampleRate}Hz',
      tag: 'AUDIO',
    );

    return AudioSamples(
      data: samples.toList(),
      sampleRate: sampleRate,
      channels: 1,
    );
  }

  /// Decodifica MP3 via buffer raw.
  /// En producción se delega al módulo C++ FFI con minimp3.
  Future<AudioSamples> _decodeMp3(File file) async {
    AppLogger.info('Decodificando MP3: ${file.path}', tag: 'AUDIO');

    // MVP: conversión simplificada.
    // En producción usar C++ FFI con minimp3 o dr_mp3.
    throw const AudioProcessingException(
      message:
          'Decodificación MP3 requiere módulo nativo C++. '
          'Use AudioLocalDataSource.loadSamplesFromMp3() con FFI.',
    );
  }
}

class AudioSamples {
  const AudioSamples({
    required this.data,
    required this.sampleRate,
    required this.channels,
  });

  final List<double> data;
  final int sampleRate;
  final int channels;

  int get length => data.length;
  double get durationSeconds => data.length / sampleRate;
}

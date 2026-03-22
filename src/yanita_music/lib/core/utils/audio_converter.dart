import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';



import 'package:path_provider/path_provider.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/core/utils/logger.dart';

/// Utilitario para conversión de formatos de audio usando FFmpeg.
/// 
/// Yanita Music requiere audio en formato WAV (PCM 16-bit, Mono, 16kHz)
/// para que el extractor de espectrograma C++ y el modelo TFLite funcionen con precisión.
class AudioConverter {
  const AudioConverter();

  /// Convierte cualquier archivo de audio soportado a WAV (16kHz, Mono).
  /// 
  /// Retorna la ruta al archivo temporal generado.
  /// Lanza [AudioProcessingException] si la conversión falla.
  Future<String> convertToWav(String inputPath) async {
    AppLogger.info('Iniciando conversión FFmpeg: $inputPath');

    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = inputPath.split('/').last.split('\\').last;
    final String outputName = '${fileName.split('.').first}_converted_${DateTime.now().millisecondsSinceEpoch}.wav';
    final String outputPath = '${tempDir.path}/$outputName';

    // Comando FFmpeg:
    // -i: Input
    // -ar 16000: Sample rate 16kHz
    // -ac 1: Mono
    // -y: Sobrescribir si existe
    final String command = '-i "$inputPath" -ar 16000 -ac 1 -y "$outputPath"';

    AppLogger.debug('Ejecutando FFmpeg: ffmpeg $command');
    
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      AppLogger.info('Conversión exitosa: $outputPath');
      
      // Copia de validación a assets/wavs
      try {
        final destDir = Directory('assets/wavs');
        if (!destDir.existsSync()) {
          destDir.createSync(recursive: true);
        }
        File(outputPath).copySync('assets/wavs/$outputName');
        AppLogger.info('Copia de validación guardada en assets/wavs/$outputName');
      } catch (e) {
        AppLogger.warning('No se pudo guardar la copia de validación en assets/wavs: $e');
      }

      return outputPath;
    } else if (ReturnCode.isCancel(returnCode)) {
      AppLogger.warning('Conversión FFmpeg cancelada por el usuario');
      throw const AudioProcessingException(message: 'Conversión cancelada');
    } else {
      final logs = await session.getAllLogsAsString();
      AppLogger.error('Error en FFmpeg: $logs');
      throw AudioProcessingException(message: 'Error al convertir audio a WAV: $returnCode');
    }

  }

  /// Elimina un archivo temporal de audio.
  void cleanTempFile(String filePath) {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
        AppLogger.debug('Archivo temporal eliminado: $filePath');
      }
    } catch (e) {
      AppLogger.warning('No se pudo eliminar el archivo temporal: $e');
    }
  }
}


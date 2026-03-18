import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:logger/logger.dart';

/// Binding FFI al módulo de procesamiento de audio en C++.
///
/// Comunica Flutter con la librería nativa que realiza:
/// - Decodificación MP3 (minimp3)
/// - Resampling a 16kHz mono
/// - Cálculo FFT (KissFFT)
/// - Generación de espectrograma Mel
///
/// El uso de C++ garantiza el alto rendimiento y baja latencia
/// requeridos para el procesamiento DSP en dispositivos móviles.

// Typedefs para funciones nativas
typedef ProcessAudioFileNative =
    Pointer<Float> Function(
      Pointer<Utf8> filePath,
      Pointer<Int32> outFrames,
      Pointer<Int32> outMelBins,
      Pointer<Double> outDuration,
    );
typedef ProcessAudioFileDart =
    Pointer<Float> Function(
      Pointer<Utf8> filePath,
      Pointer<Int32> outFrames,
      Pointer<Int32> outMelBins,
      Pointer<Double> outDuration,
    );

typedef FreeBufferNative = Void Function(Pointer<Float> buffer);
typedef FreeBufferDart = void Function(Pointer<Float> buffer);

typedef GetLastErrorNative = Pointer<Utf8> Function();
typedef GetLastErrorDart = Pointer<Utf8> Function();

/// DataSource nativo para procesamiento de audio via C++ FFI.
class AudioProcessorFFI {
  late final DynamicLibrary _nativeLib;
  late final ProcessAudioFileDart _processAudioFile;
  late final FreeBufferDart _freeBuffer;
  late final GetLastErrorDart _getLastError;
  final Logger _logger = Logger();
  bool _isInitialized = false;

  /// Inicializa la librería nativa.
  ///
  /// Debe llamarse antes de cualquier operación de procesamiento.
  void initialize() {
    if (_isInitialized) return;

    try {
      _nativeLib = _loadLibrary();

      _processAudioFile = _nativeLib
          .lookupFunction<ProcessAudioFileNative, ProcessAudioFileDart>(
            'process_audio_file',
          );

      _freeBuffer = _nativeLib.lookupFunction<FreeBufferNative, FreeBufferDart>(
        'free_buffer',
      );

      _getLastError = _nativeLib
          .lookupFunction<GetLastErrorNative, GetLastErrorDart>(
            'get_last_error',
          );

      _isInitialized = true;
      _logger.i('Módulo nativo de audio inicializado correctamente');
    } catch (e) {
      _logger.e('Error inicializando módulo nativo: $e');
      throw AudioProcessingException(
        message: 'No se pudo cargar la librería nativa de audio: $e',
      );
    }
  }

  /// Carga la librería compartida según la plataforma.
  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libaudio_processor.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else {
      throw const AudioProcessingException(
        message: 'Plataforma no soportada para procesamiento nativo de audio',
      );
    }
  }

  /// Procesa un archivo de audio y retorna el espectrograma Mel.
  ///
  /// [filePath] Ruta absoluta al archivo MP3/WAV.
  /// Retorna una tupla con (espectrograma, numFrames, numMelBins, duración).
  ({
    List<List<double>> spectrogram,
    int numFrames,
    int numMelBins,
    double duration,
  })
  processFile(String filePath) {
    if (!_isInitialized) {
      initialize();
    }

    final pathPtr = filePath.toNativeUtf8();
    final outFrames = calloc<Int32>();
    final outMelBins = calloc<Int32>();
    final outDuration = calloc<Double>();

    try {
      final resultPtr = _processAudioFile(
        pathPtr,
        outFrames,
        outMelBins,
        outDuration,
      );

      if (resultPtr == nullptr) {
        final errorPtr = _getLastError();
        final errorMsg = errorPtr.toDartString();
        throw AudioProcessingException(
          message: 'Error en procesamiento nativo: $errorMsg',
        );
      }

      final numFrames = outFrames.value;
      final numMelBins = outMelBins.value;
      final duration = outDuration.value;

      _logger.i(
        'Audio procesado: $numFrames frames, $numMelBins mel bins, '
        '${duration.toStringAsFixed(2)}s',
      );

      // Convertir buffer plano a matriz 2D
      final totalElements = numFrames * numMelBins;
      final spectrogram = <List<double>>[];

      for (var frame = 0; frame < numFrames; frame++) {
        final row = <double>[];
        for (var bin = 0; bin < numMelBins; bin++) {
          final index = frame * numMelBins + bin;
          if (index < totalElements) {
            row.add(resultPtr[index]);
          }
        }
        spectrogram.add(row);
      }

      // Liberar memoria nativa
      _freeBuffer(resultPtr);

      return (
        spectrogram: spectrogram,
        numFrames: numFrames,
        numMelBins: numMelBins,
        duration: duration,
      );
    } finally {
      calloc.free(pathPtr);
      calloc.free(outFrames);
      calloc.free(outMelBins);
      calloc.free(outDuration);
    }
  }
}

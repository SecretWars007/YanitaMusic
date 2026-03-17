/// Constantes de procesamiento de audio para el pipeline DSP en C++.
///
/// Estos valores definen los parámetros del espectrograma Mel
/// compatible con el modelo Onsets and Frames.
class AudioConstants {
  AudioConstants._();

  static const int sampleRate = 16000;
  static const int fftSize = 2048;
  static const int hopLength = 512;
  static const int numMelBins = 229;
  static const double fMin = 30.0;
  static const double fMax = 8000.0;
  static const int targetChannels = 1; // Mono
  static const int bitDepth = 16;

  // Ventana de análisis
  static const double frameDurationMs = 32.0; // hopLength / sampleRate * 1000
  static const int maxAudioDurationSec = 300; // 5 minutos máx
}

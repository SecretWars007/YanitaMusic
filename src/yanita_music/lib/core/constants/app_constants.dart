/// Constantes globales de la aplicación PianoScribe.
///
/// Centraliza valores de configuración para evitar magic numbers
/// y facilitar el mantenimiento según principios SDLC.
class AppConstants {
  AppConstants._();

  static const String appName = 'PianoScribe';
  static const String appVersion = '1.0.0';
  static const String dbName = 'piano_scribe.db';
  static const int dbVersion = 1;

  // Modelo TFLite
  static const String tfliteModelPath =
      'assets/models/onsets_and_frames.tflite';
  static const int modelInputWidth = 229;
  static const int modelInputHeight = 229;
  static const int midiNoteMin = 21; // A0
  static const int midiNoteMax = 108; // C8
  static const int numMidiNotes = 88;

  // Thresholds para detección
  static const double onsetThreshold = 0.5;
  static const double frameThreshold = 0.3;
  static const double velocityScale = 127.0;

  // MIDI/MusicXML defaults
  static const int defaultDivisions = 480;
  static const int defaultTempo = 120;

  // Métricas MIR objetivo
  static const double targetFMeasureMonophonic = 0.75;
  static const double targetFMeasurePolyphonic = 0.60;

  // Límites de archivo
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const List<String> allowedAudioExtensions = [
    '.mp3',
    '.wav',
    '.m4a',
    '.flac',
  ];
  // MIR targets
  static const double monophonicFTarget = 0.75;
  static const double polyphonicFTarget = 0.60;
  static const double onsetToleranceMs = 50.0;
}

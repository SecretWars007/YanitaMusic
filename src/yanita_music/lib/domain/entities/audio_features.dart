import 'package:equatable/equatable.dart';

/// Entidad que representa las características espectrales del audio.
///
/// Contiene el espectrograma Mel generado por el módulo C++ FFI,
/// listo para ser consumido por el modelo TFLite.
class AudioFeatures extends Equatable {
  /// Espectrograma Mel como matriz [frames x melBins].
  final List<List<double>> melSpectrogram;

  /// Número total de frames temporales.
  final int numFrames;

  /// Número de bins Mel.
  final int numMelBins;

  /// Duración total del audio en segundos.
  final double audioDuration;

  /// Sample rate utilizado en el procesamiento.
  final int sampleRate;

  /// Checksum del archivo fuente para trazabilidad.
  final String sourceChecksum;

  const AudioFeatures({
    required this.melSpectrogram,
    required this.numFrames,
    required this.numMelBins,
    required this.audioDuration,
    required this.sampleRate,
    required this.sourceChecksum,
  });

  @override
  List<Object?> get props => [
    numFrames,
    numMelBins,
    audioDuration,
    sampleRate,
    sourceChecksum,
  ];
}

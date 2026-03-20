import 'package:equatable/equatable.dart';
import 'dart:typed_data';

/// Entidad que representa las características espectrales del audio.
///
/// Contiene el espectrograma Mel generado por el módulo C++ FFI,
/// listo para ser consumido por el modelo TFLite.
class AudioFeatures extends Equatable {
  /// Espectrograma Mel como buffer plano [frames * melBins].
  final Float32List melSpectrogram;

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

  AudioFeatures copyWith({
    Float32List? melSpectrogram,
    int? numFrames,
    int? numMelBins,
    double? audioDuration,
    int? sampleRate,
    String? sourceChecksum,
  }) {
    return AudioFeatures(
      melSpectrogram: melSpectrogram ?? this.melSpectrogram,
      numFrames: numFrames ?? this.numFrames,
      numMelBins: numMelBins ?? this.numMelBins,
      audioDuration: audioDuration ?? this.audioDuration,
      sampleRate: sampleRate ?? this.sampleRate,
      sourceChecksum: sourceChecksum ?? this.sourceChecksum,
    );
  }

  @override
  List<Object?> get props => [
    numFrames,
    numMelBins,
    audioDuration,
    sampleRate,
    sourceChecksum,
  ];
}

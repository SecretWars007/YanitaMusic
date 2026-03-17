import 'package:yanita_music/domain/entities/audio_features.dart';

/// Modelo de datos para AudioFeatures.
class AudioFeaturesModel extends AudioFeatures {
  const AudioFeaturesModel({
    required super.melSpectrogram,
    required super.numFrames,
    required super.numMelBins,
    required super.audioDuration,
    required super.sampleRate,
    required super.sourceChecksum,
  });

  factory AudioFeaturesModel.fromEntity(AudioFeatures entity) {
    return AudioFeaturesModel(
      melSpectrogram: entity.melSpectrogram,
      numFrames: entity.numFrames,
      numMelBins: entity.numMelBins,
      audioDuration: entity.audioDuration,
      sampleRate: entity.sampleRate,
      sourceChecksum: entity.sourceChecksum,
    );
  }
}

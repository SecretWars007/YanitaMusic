import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/note_event.dart';

/// Caso de uso: Evaluar métricas MIR (Precision, Recall, F-measure).
///
/// Compara notas transcritas contra una referencia ground truth
/// usando tolerancia temporal configurable.
class EvaluateMetricsUseCase
    extends UseCase<TranscriptionMetrics, EvaluateMetricsParams> {
  @override
  Future<Either<Failure, TranscriptionMetrics>> call(
    EvaluateMetricsParams params,
  ) async {
    try {
      final metrics = _computeMetrics(
        params.predicted,
        params.groundTruth,
        params.onsetToleranceMs,
      );
      return Right(metrics);
    } on Exception catch (e) {
      return Left(TranscriptionFailure(message: 'Error en métricas: $e'));
    }
  }

  TranscriptionMetrics _computeMetrics(
    List<NoteEvent> predicted,
    List<NoteEvent> groundTruth,
    double toleranceMs,
  ) {
    final toleranceSec = toleranceMs / 1000.0;
    final matched = <int>{};
    var truePositives = 0;

    for (final pred in predicted) {
      for (var i = 0; i < groundTruth.length; i++) {
        if (matched.contains(i)) continue;
        final gt = groundTruth[i];
        if (pred.midiNote == gt.midiNote &&
            (pred.startTime - gt.startTime).abs() <= toleranceSec) {
          truePositives++;
          matched.add(i);
          break;
        }
      }
    }

    final precision = predicted.isEmpty
        ? 0.0
        : truePositives / predicted.length;
    final recall = groundTruth.isEmpty
        ? 0.0
        : truePositives / groundTruth.length;
    final fMeasure = (precision + recall) == 0
        ? 0.0
        : 2 * (precision * recall) / (precision + recall);

    return TranscriptionMetrics(
      precision: precision,
      recall: recall,
      fMeasure: fMeasure,
      truePositives: truePositives,
      falsePositives: predicted.length - truePositives,
      falseNegatives: groundTruth.length - truePositives,
    );
  }
}

class EvaluateMetricsParams extends Equatable {
  final List<NoteEvent> predicted;
  final List<NoteEvent> groundTruth;
  final double onsetToleranceMs;

  const EvaluateMetricsParams({
    required this.predicted,
    required this.groundTruth,
    this.onsetToleranceMs = 50.0,
  });

  @override
  List<Object?> get props => [predicted, groundTruth, onsetToleranceMs];
}

class TranscriptionMetrics extends Equatable {
  final double precision;
  final double recall;
  final double fMeasure;
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;

  const TranscriptionMetrics({
    required this.precision,
    required this.recall,
    required this.fMeasure,
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
  });

  @override
  List<Object?> get props => [
    precision,
    recall,
    fMeasure,
    truePositives,
    falsePositives,
    falseNegatives,
  ];
}

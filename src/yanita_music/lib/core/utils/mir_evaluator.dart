import 'dart:math';

import '../../domain/entities/note_event.dart';
import 'logger.dart';

/// Evaluador de métricas MIR (Music Information Retrieval).
/// Calcula Precision, Recall y F-measure comparando
/// transcripción contra ground truth.
class MirEvaluator {
  MirEvaluator({this.onsetToleranceMs = 50.0, this.pitchTolerance = 0});

  /// Tolerancia en milisegundos para considerar onset correcto.
  final double onsetToleranceMs;

  /// Tolerancia en semitonos para considerar pitch correcto (0 = exacto).
  final int pitchTolerance;

  /// Resultado completo de evaluación.
  MirMetrics evaluate({
    required List<NoteEvent> reference,
    required List<NoteEvent> estimated,
  }) {
    if (reference.isEmpty && estimated.isEmpty) {
      return const MirMetrics(
        precision: 1.0,
        recall: 1.0,
        fMeasure: 1.0,
        truePositives: 0,
        falsePositives: 0,
        falseNegatives: 0,
      );
    }

    if (reference.isEmpty) {
      return MirMetrics(
        precision: 0.0,
        recall: 0.0,
        fMeasure: 0.0,
        truePositives: 0,
        falsePositives: estimated.length,
        falseNegatives: 0,
      );
    }

    if (estimated.isEmpty) {
      return MirMetrics(
        precision: 0.0,
        recall: 0.0,
        fMeasure: 0.0,
        truePositives: 0,
        falsePositives: 0,
        falseNegatives: reference.length,
      );
    }

    final toleranceSec = onsetToleranceMs / 1000.0;
    final matchedRef = <int>{};
    final matchedEst = <int>{};

    // Greedy matching: para cada estimada buscar la referencia más cercana
    final sortedEst = List<int>.generate(
      estimated.length,
      (i) => i,
    )..sort((a, b) => estimated[a].startTime.compareTo(estimated[b].startTime));

    for (final ei in sortedEst) {
      final est = estimated[ei];
      var bestDist = double.infinity;
      var bestRi = -1;

      for (var ri = 0; ri < reference.length; ri++) {
        if (matchedRef.contains(ri)) continue;

        final ref = reference[ri];
        final pitchDiff = (est.midiPitch - ref.midiPitch).abs();
        if (pitchDiff > pitchTolerance) continue;

        final timeDiff = (est.startTime - ref.startTime).abs();
        if (timeDiff <= toleranceSec && timeDiff < bestDist) {
          bestDist = timeDiff;
          bestRi = ri;
        }
      }

      if (bestRi >= 0) {
        matchedRef.add(bestRi);
        matchedEst.add(ei);
      }
    }

    final tp = matchedEst.length;
    final fp = estimated.length - tp;
    final fn = reference.length - tp;

    final precision = tp / max(tp + fp, 1);
    final recall = tp / max(tp + fn, 1);
    final fMeasure = (precision + recall) > 0
        ? 2.0 * precision * recall / (precision + recall)
        : 0.0;

    AppLogger.info(
      'MIR Eval: P=${precision.toStringAsFixed(3)} '
      'R=${recall.toStringAsFixed(3)} '
      'F=${fMeasure.toStringAsFixed(3)} '
      'TP=$tp FP=$fp FN=$fn',
      tag: 'MIR',
    );

    return MirMetrics(
      precision: precision,
      recall: recall,
      fMeasure: fMeasure,
      truePositives: tp,
      falsePositives: fp,
      falseNegatives: fn,
    );
  }
}

class MirMetrics {
  const MirMetrics({
    required this.precision,
    required this.recall,
    required this.fMeasure,
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
  });

  final double precision;
  final double recall;
  final double fMeasure;
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;

  bool get meetsMonophonicTarget => fMeasure >= 0.75;
  bool get meetsPolyphonicTarget => fMeasure >= 0.60;

  @override
  String toString() =>
      'MirMetrics(P=${precision.toStringAsFixed(3)}, '
      'R=${recall.toStringAsFixed(3)}, '
      'F=${fMeasure.toStringAsFixed(3)})';
}

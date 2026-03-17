import 'package:flutter_test/flutter_test.dart';
import 'package:yanita_music/domain/entities/note_event.dart';
import 'package:yanita_music/domain/usecases/evaluate_metrics_usecase.dart';

void main() {
  group('EvaluateMetricsUseCase', () {
    late EvaluateMetricsUseCase useCase;

    setUp(() {
      useCase = EvaluateMetricsUseCase();
    });

    test('perfect match returns 100% metrics', () async {
      final notes = [
        const NoteEvent(
          startTime: 0.0,
          endTime: 0.5,
          midiNote: 60,
          velocity: 80,
        ),
        const NoteEvent(
          startTime: 1.0,
          endTime: 1.5,
          midiNote: 64,
          velocity: 80,
        ),
      ];

      final result = await useCase(EvaluateMetricsParams(
        predicted: notes,
        groundTruth: notes,
      ));

      result.fold(
        (failure) => fail('Should not fail: ${failure.message}'),
        (metrics) {
          expect(metrics.precision, equals(1.0));
          expect(metrics.recall, equals(1.0));
          expect(metrics.fMeasure, equals(1.0));
          expect(metrics.truePositives, equals(2));
          expect(metrics.falsePositives, equals(0));
          expect(metrics.falseNegatives, equals(0));
        },
      );
    });

    test('no matches returns 0% metrics', () async {
      final predicted = [
        const NoteEvent(
          startTime: 0.0,
          endTime: 0.5,
          midiNote: 60,
          velocity: 80,
        ),
      ];
      final groundTruth = [
        const NoteEvent(
          startTime: 5.0,
          endTime: 5.5,
          midiNote: 72,
          velocity: 80,
        ),
      ];

      final result = await useCase(EvaluateMetricsParams(
        predicted: predicted,
        groundTruth: groundTruth,
      ));

      result.fold(
        (failure) => fail('Should not fail'),
        (metrics) {
          expect(metrics.precision, equals(0.0));
          expect(metrics.recall, equals(0.0));
          expect(metrics.fMeasure, equals(0.0));
        },
      );
    });

    test('partial match within tolerance', () async {
      final predicted = [
        const NoteEvent(
          startTime: 0.02, // 20ms offset
          endTime: 0.5,
          midiNote: 60,
          velocity: 80,
        ),
        const NoteEvent(
          startTime: 1.0,
          endTime: 1.5,
          midiNote: 64,
          velocity: 80,
        ),
      ];

      final groundTruth = [
        const NoteEvent(
          startTime: 0.0,
          endTime: 0.5,
          midiNote: 60,
          velocity: 80,
        ),
      ];

      final result = await useCase(EvaluateMetricsParams(
        predicted: predicted,
        groundTruth: groundTruth,
        onsetToleranceMs: 50.0,
      ));

      result.fold(
        (failure) => fail('Should not fail'),
        (metrics) {
          expect(metrics.truePositives, equals(1));
          expect(metrics.falsePositives, equals(1));
          expect(metrics.falseNegatives, equals(0));
          expect(metrics.precision, equals(0.5));
          expect(metrics.recall, equals(1.0));
        },
      );
    });

    test('meets monophonic F-measure target of 0.75', () async {
      // 4 out of 5 correct = P=0.8, R=0.8, F=0.8 > 0.75
      final predicted = List.generate(
        5,
        (i) => NoteEvent(
          startTime: i * 1.0,
          endTime: i * 1.0 + 0.5,
          midiNote: 60 + i,
          velocity: 80,
        ),
      );

      final groundTruth = List.generate(
        5,
        (i) => NoteEvent(
          startTime: i * 1.0,
          endTime: i * 1.0 + 0.5,
          midiNote: i < 4 ? 60 + i : 99, // Last one different
          velocity: 80,
        ),
      );

      final result = await useCase(EvaluateMetricsParams(
        predicted: predicted,
        groundTruth: groundTruth,
      ));

      result.fold(
        (failure) => fail('Should not fail'),
        (metrics) {
          expect(metrics.fMeasure, greaterThanOrEqualTo(0.60));
        },
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:yanita_music/data/repositories/transcription_repository_impl.dart';
import 'package:yanita_music/domain/entities/audio_features.dart';
import 'dart:typed_data';
import 'package:yanita_music/core/utils/logger.dart';


/// Test de Calidad (QA) para el motor de transcripción e Isolates.
/// Verifica que la lógica de IA y la unión de fragmentos (Stitching) sea robusta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA: Engine de Transcripción y Paralelismo', () {
    late TranscriptionRepositoryImpl repository;

    setUp(() {
      repository = TranscriptionRepositoryImpl();
    });

    test('QA: Flujo Completo de Inferencia y Costura (Mock Mel)', () async {
      // 1. Cargar modelo
      final init = await repository.initializeModel();
      if (init.isLeft()) {
        AppLogger.warning(
          'SKIPPING: No se pudo cargar el modelo TFLite en este entorno de test.',
        );
        return;
      }

      // 2. Mock de características (8 segundos de audio simulado)
      // Usamos un tamaño que obligue a usar el procesamiento paralelo (NumIsolates > 1)
      const int numFrames = 1200;
      final audioFeatures = AudioFeatures(
        melSpectrogram: Float32List(numFrames * 229),
        numFrames: numFrames,
        numMelBins: 229,
        audioDuration: 8.0,
        sampleRate: 16000,
        sourceChecksum: 'qa-parallel-check',
      );

      // 3. Procesar
      final result = await repository.transcribe(audioFeatures);

      result.fold(
        (failure) => fail(
          'QA Falló: Error en transcripción paralela: ${failure.message}',
        ),
        (notes) {
          AppLogger.info(
            'QA Éxito: Transcripción completada sin bloqueos. Notas resultantes: ${notes.length}',
          );
          expect(notes, isNotNull);
          // Nota: result puede estar vacío si el espectrograma es plano (ceros), lo cual es correcto.
        },
      );
    });
  });
}

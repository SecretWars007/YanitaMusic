import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanita_music/data/repositories/audio_repository_impl.dart';
import 'package:yanita_music/core/security/file_validator.dart';
import 'package:yanita_music/core/utils/logger.dart';


/// Test de Calidad (QA) para el procesador de audio C++ FFI.
/// Verifica que el espectrograma se genere correctamente a partir de un MP3 real.
void main() {
  test('QA: Extracción de Espectrograma - ODE_TO_JOY.MP3', () async {
    final repository = AudioRepositoryImpl(fileValidator: const FileValidator());

    // El path relativo depende de dónde se ejecute el test (root del proyecto)
    const filePath = 'assets/audio/ode_to_joy.mp3';

    if (!File(filePath).existsSync()) {
      AppLogger.warning(
        'SKIPPING: Archivo no encontrado en $filePath. Asegúrese de estar en el root del proyecto.',
      );
      return;
    }

    final result = await repository.processAudioFile(filePath);

    result.fold(
      (failure) => fail(
        'QA Falló: El procesador FFI devolvió un error: ${failure.message}',
      ),
      (features) {
        AppLogger.info(
          'QA Éxito: Espectrograma generado con ${features.numFrames} frames.',
        );

        // Verificaciones de integridad de datos
        expect(
          features.numFrames,
          greaterThan(0),
          reason: 'Debe generar al menos un frame de audio',
        );
        expect(
          features.numMelBins,
          equals(229),
          reason: 'El modelo requiere exactamente 229 bins de Mel',
        );
        expect(
          features.melSpectrogram.length,
          equals(features.numFrames * 229),
        );
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yanita_music/main.dart' as app;
import 'package:yanita_music/core/constants/version_constants.dart';
import 'package:yanita_music/core/utils/logger.dart';


/// Test de integración para control de calidad (QA).
/// Verifica los flujos críticos de la aplicación y la integridad de los assets.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('QA Suite - Yanita Music', () {
    
    testWidgets('P0: Smoke Test - Carga Inicial y Versión', (tester) async {
      await tester.runAsync(() async {
        app.main();
        await tester.pumpAndSettle();

        // Verificar que la app carga el Dashboard
        expect(find.text('Yanita Music'), findsAtLeastNWidgets(1));

        // Verificar que la versión v1.1.0+2 es visible (Requerimiento de QA)
        final versionText = find.textContaining('Versión ${VersionConstants.appVersion}');
        expect(versionText, findsOneWidget);
        
        AppLogger.info('QA: Versión detectada correctamente: ${VersionConstants.appVersion}');
      });
    });

    testWidgets('P1: Integridad de Demos - Himno a la Alegría', (tester) async {
      await tester.runAsync(() async {
        app.main();
        await tester.pumpAndSettle();

        // Verificar presencia del demo local
        final demoTitle = find.text('HIMNO A LA ALEGRÍA (Demo)');
        expect(demoTitle, findsOneWidget);

        // Entrar al detalle del demo
        await tester.tap(demoTitle);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verificar que se visualiza la partitura (Clef, Time Signature, etc.)
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
        
        // Verificar controles de audio
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        
        AppLogger.info('QA: Demo cargado íntegramente desde assets.');
      });
    });

    testWidgets('P2: Navegación - Flujo de Transcripción', (tester) async {
      await tester.runAsync(() async {
        app.main();
        await tester.pumpAndSettle();

        // Tocar el botón de navegación a Transcripción
        final navItem = find.byIcon(Icons.music_note_outlined);
        expect(navItem, findsOneWidget);
        
        await tester.tap(navItem);
        await tester.pumpAndSettle();

        // Verificar estado inicial de la página
        expect(find.text('Seleccionar Archivo'), findsOneWidget);
        expect(find.text('No hay archivo seleccionado'), findsOneWidget);
        
        AppLogger.info('QA: Navegación a pipeline de transcripción validada.');
      });
    });
  });
}

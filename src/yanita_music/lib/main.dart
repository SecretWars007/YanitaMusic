import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yanita_music/injection_container.dart' as di;
import 'package:yanita_music/presentation/blocs/transcription/transcription_bloc.dart';
import 'package:yanita_music/presentation/blocs/score_library/score_library_bloc.dart';
import 'package:yanita_music/presentation/blocs/songbook/songbook_bloc.dart';

import 'package:yanita_music/presentation/pages/splash_screen.dart';
import 'package:yanita_music/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [OFFLINE OPTIMIZATION]: Desactivar descarga de fuentes en tiempo de ejecución
  GoogleFonts.config.allowRuntimeFetching = false;

  // Inicializar inyección de dependencias
  await di.initDependencies();

  runApp(const PianoScribeApp());
}

/// Aplicación principal: PianoScribe - Transcripción Musical AMT.
class PianoScribeApp extends StatelessWidget {
  const PianoScribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TranscriptionBloc>(
          create: (_) => di.sl<TranscriptionBloc>(),
        ),
        BlocProvider<ScoreLibraryBloc>(
          create: (_) => di.sl<ScoreLibraryBloc>(),
        ),
        BlocProvider<SongbookBloc>(
          create: (_) => di.sl<SongbookBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Yanita Music',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

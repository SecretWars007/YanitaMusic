import 'package:get_it/get_it.dart';
import 'package:yanita_music/core/security/file_validator.dart';
import 'package:yanita_music/core/utils/midi_utils.dart';
import 'package:yanita_music/core/utils/music_xml_generator.dart';
import 'package:yanita_music/data/datasources/local/database_helper.dart';
import 'package:yanita_music/data/datasources/local/score_local_datasource.dart';
import 'package:yanita_music/data/datasources/local/songbook_local_datasource.dart';
import 'package:yanita_music/data/repositories/audio_repository_impl.dart';
import 'package:yanita_music/data/repositories/score_repository_impl.dart';
import 'package:yanita_music/data/repositories/songbook_repository_impl.dart';
import 'package:yanita_music/data/repositories/transcription_repository_impl.dart';
import 'package:yanita_music/domain/repositories/audio_repository.dart';
import 'package:yanita_music/domain/repositories/score_repository.dart';
import 'package:yanita_music/domain/repositories/songbook_repository.dart';
import 'package:yanita_music/domain/repositories/transcription_repository.dart';
import 'package:yanita_music/domain/usecases/add_song_usecase.dart';
import 'package:yanita_music/domain/usecases/delete_score_usecase.dart';
import 'package:yanita_music/domain/usecases/export_midi_usecase.dart';
import 'package:yanita_music/domain/usecases/export_musicxml_usecase.dart';
import 'package:yanita_music/domain/usecases/get_scores_usecase.dart';
import 'package:yanita_music/domain/usecases/get_songs_usecase.dart';
import 'package:yanita_music/domain/usecases/process_audio_usecase.dart';
import 'package:yanita_music/domain/usecases/save_score_usecase.dart';
import 'package:yanita_music/domain/usecases/transcribe_audio_usecase.dart';
import 'package:yanita_music/presentation/blocs/score_library/score_library_bloc.dart';
import 'package:yanita_music/presentation/blocs/songbook/songbook_bloc.dart';
import 'package:yanita_music/presentation/blocs/transcription/transcription_bloc.dart';

/// Service Locator global usando get_it.
///
/// Registra todas las dependencias siguiendo el patrón de
/// inyección de dependencias de Clean Architecture:
/// DataSources → Repositories → UseCases → BLoCs
final sl = GetIt.instance;

/// Inicializa todas las dependencias.
Future<void> initDependencies() async {
  // ──────────────── Core ────────────────
  sl.registerLazySingleton<FileValidator>(() => const FileValidator());
  sl.registerLazySingleton<MidiUtils>(() => MidiUtils());
  sl.registerLazySingleton<MusicXmlGenerator>(() => MusicXmlGenerator());

  // ──────────────── Data: DataSources ────────────────
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());

  sl.registerLazySingleton<ScoreLocalDataSource>(
    () => ScoreLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<SongbookLocalDataSource>(
    () => SongbookLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ──────────────── Data: Repositories ────────────────
  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(
      fileValidator: sl(),
    ),
  );

  sl.registerLazySingleton<TranscriptionRepository>(
    () => TranscriptionRepositoryImpl(),
  );

  sl.registerLazySingleton<ScoreRepository>(
    () => ScoreRepositoryImpl(
      localDataSource: sl(),
      midiUtils: sl(),
      musicXmlGenerator: sl(),
    ),
  );

  sl.registerLazySingleton<SongbookRepository>(
    () => SongbookRepositoryImpl(localDataSource: sl()),
  );

  // ──────────────── Domain: Use Cases ────────────────
  sl.registerLazySingleton(
    () => ProcessAudioUseCase(
      audioRepository: sl(),
      fileValidator: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => TranscribeAudioUseCase(transcriptionRepository: sl()),
  );

  sl.registerLazySingleton(
    () => SaveScoreUseCase(scoreRepository: sl()),
  );

  sl.registerLazySingleton(
    () => GetScoresUseCase(scoreRepository: sl()),
  );

  sl.registerLazySingleton(
    () => DeleteScoreUseCase(scoreRepository: sl()),
  );

  sl.registerLazySingleton(
    () => ExportMidiUseCase(scoreRepository: sl()),
  );

  sl.registerLazySingleton(
    () => ExportMusicXmlUseCase(scoreRepository: sl()),
  );

  sl.registerLazySingleton(
    () => AddSongUseCase(songbookRepository: sl()),
  );

  sl.registerLazySingleton(
    () => GetSongsUseCase(songbookRepository: sl()),
  );

  // ──────────────── Presentation: BLoCs ────────────────
  sl.registerFactory(
    () => TranscriptionBloc(
      processAudioUseCase: sl(),
      transcribeAudioUseCase: sl(),
      saveScoreUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ScoreLibraryBloc(
      getScoresUseCase: sl(),
      deleteScoreUseCase: sl(),
      exportMidiUseCase: sl(),
      exportMusicXmlUseCase: sl(),
      saveScoreUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => SongbookBloc(
      getSongsUseCase: sl(),
      addSongUseCase: sl(),
      songbookRepository: sl(),
    ),
  );
}

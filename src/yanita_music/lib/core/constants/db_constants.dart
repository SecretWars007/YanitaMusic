/// Constantes de la base de datos SQLite.
///
/// Define nombres de tablas y columnas para mantener consistencia
/// y evitar errores de tipeo en queries SQL.
class DbConstants {
  DbConstants._();

  // Tabla de partituras
  static const String scoresTable = 'scores';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colAudioPath = 'audio_path';
  static const String colMidiData = 'midi_data';
  static const String colMusicXml = 'music_xml';
  static const String colNoteEvents = 'note_events';
  static const String colDuration = 'duration';
  static const String colTempo = 'tempo';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colChecksum = 'checksum';
  static const String colSpectrogramData = 'spectrogram_data';

  // Tabla del cancionero (songbook)
  static const String songsTable = 'songs'; // Nueva tabla para demos y gestión simplificada
  static const String songbookTable = 'songs'; // Alias para compatibilidad con código existente
  static const String colSongId = 'id';
  static const String colSongTitle = 'title';
  static const String colArtist = 'artist';
  static const String colScorePath = 'score_path';
  static const String colCoverPath = 'cover_path';
  static const String colIsDemo = 'is_demo';
  static const String colCategory = 'category'; // Reintegrado
  static const String colDifficulty = 'difficulty'; // Reintegrado
  static const String colIsFavorite = 'is_favorite'; // Reintegrado
  static const String colSongCreatedAt = 'created_at';

  // Tabla de métricas
  static const String metricsTable = 'metrics';
  static const String colMetricId = 'id';
  static const String colMetricScoreId = 'score_id';
  static const String colPrecision = 'precision_val';
  static const String colRecall = 'recall_val';
  static const String colFMeasure = 'f_measure';
  static const String colIsPolyphonic = 'is_polyphonic';
  static const String colMetricCreatedAt = 'created_at';

  // Tabla de logs persistentes
  static const String logsTable = 'app_logs';
  static const String colLogId = 'id';
  static const String colLogLevel = 'level'; // info, warning, error, debug
  static const String colLogMessage = 'message';
  static const String colLogTag = 'tag'; // Componente que genera el log
  static const String colLogStackTrace = 'stack_trace';
  static const String colLogCreatedAt = 'created_at';
}

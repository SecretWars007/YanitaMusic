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

  // Tabla del cancionero
  static const String songbookTable = 'songbook';
  static const String colSongId = 'id';
  static const String colSongTitle = 'song_title';
  static const String colArtist = 'artist';
  static const String colScoreId = 'score_id';
  static const String colCategory = 'category';
  static const String colDifficulty = 'difficulty';
  static const String colIsFavorite = 'is_favorite';
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
}

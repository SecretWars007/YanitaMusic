import 'package:yanita_music/core/constants/db_constants.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/data/datasources/local/database_helper.dart';
import 'package:yanita_music/data/models/song_model.dart';
import 'package:logger/logger.dart';

abstract class SongbookLocalDataSource {
  Future<SongModel> insertSong(SongModel song);
  Future<List<SongModel>> getAllSongs();
  Future<List<SongModel>> getSongsByCategory(String category);
  Future<List<SongModel>> getFavorites();
  Future<SongModel> updateSong(SongModel song);
  Future<void> deleteSong(String id);
  Future<List<SongModel>> searchSongs(String query);
}

class SongbookLocalDataSourceImpl implements SongbookLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Logger _logger = Logger();

  SongbookLocalDataSourceImpl({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  @override
  Future<SongModel> insertSong(SongModel song) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(DbConstants.songbookTable, song.toMap());
      _logger.i('Canción agregada al cancionero: ${song.id}');
      return song;
    } catch (e) {
      throw DatabaseException('Error al agregar canción: $e');
    }
  }

  @override
  Future<List<SongModel>> getAllSongs() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DbConstants.songbookTable,
        orderBy: '${DbConstants.colSongCreatedAt} DESC',
      );
      return maps.map((map) => SongModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Error al obtener canciones: $e');
    }
  }

  @override
  Future<List<SongModel>> getSongsByCategory(String category) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DbConstants.songbookTable,
        where: '${DbConstants.colCategory} = ?',
        whereArgs: [category],
        orderBy: '${DbConstants.colSongTitle} ASC',
      );
      return maps.map((map) => SongModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Error al filtrar canciones: $e');
    }
  }

  @override
  Future<List<SongModel>> getFavorites() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DbConstants.songbookTable,
        where: '${DbConstants.colIsFavorite} = ?',
        whereArgs: [1],
        orderBy: '${DbConstants.colSongTitle} ASC',
      );
      return maps.map((map) => SongModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Error al obtener favoritos: $e');
    }
  }

  @override
  Future<SongModel> updateSong(SongModel song) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DbConstants.songbookTable,
        song.toMap(),
        where: '${DbConstants.colSongId} = ?',
        whereArgs: [song.id],
      );
      return song;
    } catch (e) {
      throw DatabaseException('Error al actualizar canción: $e');
    }
  }

  @override
  Future<void> deleteSong(String id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DbConstants.songbookTable,
        where: '${DbConstants.colSongId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Error al eliminar canción: $e');
    }
  }

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DbConstants.songbookTable,
        where:
            '${DbConstants.colSongTitle} LIKE ? OR ${DbConstants.colArtist} LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: '${DbConstants.colSongTitle} ASC',
      );
      return maps.map((map) => SongModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Error en búsqueda: $e');
    }
  }
}

import 'package:yanita_music/core/constants/db_constants.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/data/datasources/local/database_helper.dart';
import 'package:yanita_music/data/models/score_model.dart';
import 'package:logger/logger.dart';

/// DataSource local para operaciones CRUD de partituras en SQLite.
///
/// Utiliza queries parametrizadas para prevenir SQL injection.
abstract class ScoreLocalDataSource {
  Future<ScoreModel> insertScore(ScoreModel score);
  Future<List<ScoreModel>> getAllScores();
  Future<ScoreModel> getScoreById(String id);
  Future<void> deleteScore(String id);
  Future<ScoreModel> updateScore(ScoreModel score);
}

class ScoreLocalDataSourceImpl implements ScoreLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Logger _logger = Logger();

  ScoreLocalDataSourceImpl({required DatabaseHelper databaseHelper})
    : _databaseHelper = databaseHelper;

  @override
  Future<ScoreModel> insertScore(ScoreModel score) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(DbConstants.scoresTable, score.toMap());
      _logger.i('Partitura guardada: ${score.id}');
      return score;
    } catch (e) {
      _logger.e('Error insertando partitura: $e');
      throw DatabaseException('Error al guardar partitura: $e');
    }
  }

  @override
  Future<List<ScoreModel>> getAllScores() async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DbConstants.scoresTable,
        orderBy: '${DbConstants.colCreatedAt} DESC',
      );
      return maps.map((map) => ScoreModel.fromMap(map)).toList();
    } catch (e) {
      _logger.e('Error obteniendo partituras: $e');
      throw DatabaseException('Error al obtener partituras: $e');
    }
  }

  @override
  Future<ScoreModel> getScoreById(String id) async {
    try {
      final db = await _databaseHelper.database;
      final maps = await db.query(
        DbConstants.scoresTable,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) {
        throw const DatabaseException('Partitura no encontrada');
      }
      return ScoreModel.fromMap(maps.first);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Error al obtener partitura: $e');
    }
  }

  @override
  Future<void> deleteScore(String id) async {
    try {
      final db = await _databaseHelper.database;
      final count = await db.delete(
        DbConstants.scoresTable,
        where: '${DbConstants.colId} = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException('Partitura no encontrada para eliminar');
      }
      _logger.i('Partitura eliminada: $id');
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Error al eliminar partitura: $e');
    }
  }

  @override
  Future<ScoreModel> updateScore(ScoreModel score) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        DbConstants.scoresTable,
        score.toMap(),
        where: '${DbConstants.colId} = ?',
        whereArgs: [score.id],
      );
      _logger.i('Partitura actualizada: ${score.id}');
      return score;
    } catch (e) {
      throw DatabaseException('Error al actualizar partitura: $e');
    }
  }
}

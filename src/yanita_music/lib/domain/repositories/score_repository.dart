import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/domain/entities/score.dart';

/// Contrato del repositorio de partituras.
///
/// CRUD completo para partituras almacenadas en SQLite.
abstract class ScoreRepository {
  Future<Either<Failure, Score>> saveScore(Score score);
  Future<Either<Failure, List<Score>>> getAllScores();
  Future<Either<Failure, Score>> getScoreById(String id);
  Future<Either<Failure, void>> deleteScore(String id);
  Future<Either<Failure, Score>> updateScore(Score score);
  Future<Either<Failure, String>> exportMidi(String scoreId);
  Future<Either<Failure, String>> exportMusicXml(String scoreId);
}

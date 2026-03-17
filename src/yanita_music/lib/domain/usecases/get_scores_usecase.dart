import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/domain/repositories/score_repository.dart';

/// Caso de uso: Obtener todas las partituras almacenadas.
class GetScoresUseCase extends UseCase<List<Score>, NoParams> {
  final ScoreRepository _scoreRepository;

  GetScoresUseCase({required ScoreRepository scoreRepository})
    : _scoreRepository = scoreRepository;

  @override
  Future<Either<Failure, List<Score>>> call(NoParams params) async {
    return await _scoreRepository.getAllScores();
  }
}

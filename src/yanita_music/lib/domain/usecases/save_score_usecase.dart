import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/score.dart';
import 'package:yanita_music/domain/repositories/score_repository.dart';

/// Caso de uso: Guardar partitura transcrita en SQLite.
class SaveScoreUseCase extends UseCase<Score, SaveScoreParams> {
  final ScoreRepository _scoreRepository;

  SaveScoreUseCase({required ScoreRepository scoreRepository})
    : _scoreRepository = scoreRepository;

  @override
  Future<Either<Failure, Score>> call(SaveScoreParams params) async {
    return await _scoreRepository.saveScore(params.score);
  }
}

class SaveScoreParams extends Equatable {
  final Score score;

  const SaveScoreParams({required this.score});

  @override
  List<Object?> get props => [score];
}

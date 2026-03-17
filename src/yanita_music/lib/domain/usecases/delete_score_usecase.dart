import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/repositories/score_repository.dart';

class DeleteScoreUseCase extends UseCase<void, DeleteScoreParams> {
  final ScoreRepository _scoreRepository;

  DeleteScoreUseCase({required ScoreRepository scoreRepository})
    : _scoreRepository = scoreRepository;

  @override
  Future<Either<Failure, void>> call(DeleteScoreParams params) async {
    return await _scoreRepository.deleteScore(params.scoreId);
  }
}

class DeleteScoreParams extends Equatable {
  final String scoreId;

  const DeleteScoreParams({required this.scoreId});

  @override
  List<Object?> get props => [scoreId];
}

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/repositories/score_repository.dart';

class ExportMidiUseCase extends UseCase<String, ExportMidiParams> {
  final ScoreRepository _scoreRepository;

  ExportMidiUseCase({required ScoreRepository scoreRepository})
    : _scoreRepository = scoreRepository;

  @override
  Future<Either<Failure, String>> call(ExportMidiParams params) async {
    return await _scoreRepository.exportMidi(params.scoreId);
  }
}

class ExportMidiParams extends Equatable {
  final String scoreId;

  const ExportMidiParams({required this.scoreId});

  @override
  List<Object?> get props => [scoreId];
}

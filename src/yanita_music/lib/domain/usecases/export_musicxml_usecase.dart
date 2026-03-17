import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/repositories/score_repository.dart';

class ExportMusicXmlUseCase extends UseCase<String, ExportMusicXmlParams> {
  final ScoreRepository _scoreRepository;

  ExportMusicXmlUseCase({required ScoreRepository scoreRepository})
    : _scoreRepository = scoreRepository;

  @override
  Future<Either<Failure, String>> call(ExportMusicXmlParams params) async {
    return await _scoreRepository.exportMusicXml(params.scoreId);
  }
}

class ExportMusicXmlParams extends Equatable {
  final String scoreId;

  const ExportMusicXmlParams({required this.scoreId});

  @override
  List<Object?> get props => [scoreId];
}

import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/song.dart';
import 'package:yanita_music/domain/repositories/songbook_repository.dart';

class GetSongsUseCase extends UseCase<List<Song>, NoParams> {
  final SongbookRepository _songbookRepository;

  GetSongsUseCase({required SongbookRepository songbookRepository})
    : _songbookRepository = songbookRepository;

  @override
  Future<Either<Failure, List<Song>>> call(NoParams params) async {
    return await _songbookRepository.getAllSongs();
  }
}

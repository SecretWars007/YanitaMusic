import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/core/usecases/usecase.dart';
import 'package:yanita_music/domain/entities/song.dart';
import 'package:yanita_music/domain/repositories/songbook_repository.dart';

class AddSongUseCase extends UseCase<Song, AddSongParams> {
  final SongbookRepository _songbookRepository;

  AddSongUseCase({required SongbookRepository songbookRepository})
    : _songbookRepository = songbookRepository;

  @override
  Future<Either<Failure, Song>> call(AddSongParams params) async {
    return await _songbookRepository.addSong(params.song);
  }
}

class AddSongParams extends Equatable {
  final Song song;

  const AddSongParams({required this.song});

  @override
  List<Object?> get props => [song];
}

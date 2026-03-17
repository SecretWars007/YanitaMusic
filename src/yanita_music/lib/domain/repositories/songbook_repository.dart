import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/domain/entities/song.dart';

/// Contrato del repositorio del cancionero.
abstract class SongbookRepository {
  Future<Either<Failure, Song>> addSong(Song song);
  Future<Either<Failure, List<Song>>> getAllSongs();
  Future<Either<Failure, List<Song>>> getSongsByCategory(String category);
  Future<Either<Failure, List<Song>>> getFavorites();
  Future<Either<Failure, Song>> updateSong(Song song);
  Future<Either<Failure, void>> deleteSong(String id);
  Future<Either<Failure, List<Song>>> searchSongs(String query);
}

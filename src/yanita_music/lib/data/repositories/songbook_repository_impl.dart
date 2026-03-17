import 'package:dartz/dartz.dart';
import 'package:yanita_music/core/error/exceptions.dart';
import 'package:yanita_music/core/error/failures.dart';
import 'package:yanita_music/data/datasources/local/songbook_local_datasource.dart';
import 'package:yanita_music/data/models/song_model.dart';
import 'package:yanita_music/domain/entities/song.dart';
import 'package:yanita_music/domain/repositories/songbook_repository.dart';

class SongbookRepositoryImpl implements SongbookRepository {
  final SongbookLocalDataSource _localDataSource;

  SongbookRepositoryImpl({required SongbookLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, Song>> addSong(Song song) async {
    try {
      final model = SongModel.fromEntity(song);
      final result = await _localDataSource.insertSong(model);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Song>>> getAllSongs() async {
    try {
      final songs = await _localDataSource.getAllSongs();
      return Right(songs);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Song>>> getSongsByCategory(
    String category,
  ) async {
    try {
      final songs = await _localDataSource.getSongsByCategory(category);
      return Right(songs);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Song>>> getFavorites() async {
    try {
      final songs = await _localDataSource.getFavorites();
      return Right(songs);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Song>> updateSong(Song song) async {
    try {
      final model = SongModel.fromEntity(song);
      final result = await _localDataSource.updateSong(model);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSong(String id) async {
    try {
      await _localDataSource.deleteSong(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<Song>>> searchSongs(String query) async {
    try {
      final songs = await _localDataSource.searchSongs(query);
      return Right(songs);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }
}

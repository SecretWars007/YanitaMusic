import 'package:yanita_music/domain/entities/song.dart';

/// Modelo de datos para Song con serialización SQLite.
class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    super.artist,
    required super.scoreId,
    super.category,
    super.difficulty,
    super.isFavorite,
    required super.createdAt,
  });

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      title: map['song_title'] as String,
      artist: map['artist'] as String?,
      scoreId: map['score_id'] as String,
      category: map['category'] as String?,
      difficulty: map['difficulty'] as int? ?? 3,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'song_title': title,
      'artist': artist,
      'score_id': scoreId,
      'category': category,
      'difficulty': difficulty,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SongModel.fromEntity(Song entity) {
    return SongModel(
      id: entity.id,
      title: entity.title,
      artist: entity.artist,
      scoreId: entity.scoreId,
      category: entity.category,
      difficulty: entity.difficulty,
      isFavorite: entity.isFavorite,
      createdAt: entity.createdAt,
    );
  }
}

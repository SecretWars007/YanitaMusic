import 'package:equatable/equatable.dart';

/// Entidad del cancionero del usuario.
///
/// Asocia metadata de canción con su partitura transcrita.
class Song extends Equatable {
  final String id;
  final String title;
  final String? artist;
  final String scoreId;
  final String? category;
  final int difficulty; // 1-5
  final bool isFavorite;
  final DateTime createdAt;

  const Song({
    required this.id,
    required this.title,
    this.artist,
    required this.scoreId,
    this.category,
    this.difficulty = 3,
    this.isFavorite = false,
    required this.createdAt,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? scoreId,
    String? category,
    int? difficulty,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      scoreId: scoreId ?? this.scoreId,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, scoreId, isFavorite];
}

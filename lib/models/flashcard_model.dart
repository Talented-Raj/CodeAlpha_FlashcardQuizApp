import 'dart:convert';

class FlashcardModel {
  final int? id;
  final String front;
  final String back;
  final String category;
  final bool isFavorite;
  final int box; // Leitner Box number (typically 1 to 5)
  final DateTime nextReviewDate;
  final DateTime createdAt;

  FlashcardModel({
    this.id,
    required this.front,
    required this.back,
    required this.category,
    this.isFavorite = false,
    this.box = 1,
    required this.nextReviewDate,
    required this.createdAt,
  });

  FlashcardModel copyWith({
    int? id,
    String? front,
    String? back,
    String? category,
    bool? isFavorite,
    int? box,
    DateTime? nextReviewDate,
    DateTime? createdAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      box: box ?? this.box,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0, // SQLite stores boolean as 0/1
      'box': box,
      'next_review_date': nextReviewDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as int?,
      front: map['front'] as String,
      back: map['back'] as String,
      category: map['category'] as String,
      isFavorite: (map['is_favorite'] as int) == 1,
      box: map['box'] as int,
      nextReviewDate: DateTime.parse(map['next_review_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory FlashcardModel.fromJson(String source) =>
      FlashcardModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FlashcardModel(id: $id, front: $front, back: $back, category: $category, isFavorite: $isFavorite, box: $box, nextReviewDate: $nextReviewDate, createdAt: $createdAt)';
  }
}

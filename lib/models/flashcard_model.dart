import 'dart:convert';

class FlashcardModel {
  final int? id;
  final String question;
  final String answer;
  final String category;
  final String difficulty; // "Easy", "Medium", "Hard"
  final bool favorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardModel({
    this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.difficulty,
    this.favorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  FlashcardModel copyWith({
    int? id,
    String? question,
    String? answer,
    String? category,
    String? difficulty,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'difficulty': difficulty,
      'favorite': favorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as int?,
      question: map['question'] as String,
      answer: map['answer'] as String,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String? ?? 'Medium',
      favorite: (map['favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory FlashcardModel.fromJson(String source) =>
      FlashcardModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FlashcardModel(id: $id, question: $question, answer: $answer, category: $category, difficulty: $difficulty, favorite: $favorite, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

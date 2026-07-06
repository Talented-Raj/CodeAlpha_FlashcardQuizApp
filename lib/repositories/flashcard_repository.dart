import '../models/flashcard_model.dart';

abstract class FlashcardRepository {
  /// Inserts a new flashcard into the database.
  /// Returns the flashcard with its generated autoincrement ID.
  Future<FlashcardModel> insertFlashcard(FlashcardModel card);

  /// Retrieves a specific flashcard by its unique ID.
  /// Returns null if no card with that ID exists.
  Future<FlashcardModel?> getFlashcardById(int id);

  /// Retrieves all flashcards from the database.
  Future<List<FlashcardModel>> getAllFlashcards();

  /// Updates an existing flashcard.
  /// Returns the number of affected rows.
  Future<int> updateFlashcard(FlashcardModel card);

  /// Deletes a flashcard from the database by its ID.
  /// Returns the number of affected rows.
  Future<int> deleteFlashcard(int id);

  /// Searches flashcards where front text or back text matches the query.
  Future<List<FlashcardModel>> searchFlashcards(String query);

  /// Retrieves flashcards matching a specific category.
  Future<List<FlashcardModel>> getFlashcardsByCategory(String category);

  /// Retrieves flashcards marked as favorites.
  Future<List<FlashcardModel>> getFavoriteFlashcards();

  /// Retrieves a list of all distinct category names present in the database.
  Future<List<String>> getCategories();

  /// Retrieves flashcards that are due for review (nextReviewDate <= current time).
  Future<List<FlashcardModel>> getDueFlashcards();

  /// Retrieves flashcards filtered by category, favorite status, and sorted by a specific field.
  /// Supported values for [sortBy]: 'front', 'box', 'next_review_date', 'created_at'.
  Future<List<FlashcardModel>> getFlashcardsFiltered({
    String? category,
    bool? isFavorite,
    String? sortBy,
    bool sortAscending = true,
  });
}

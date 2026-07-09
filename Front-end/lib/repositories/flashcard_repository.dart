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

  /// Searches flashcards where question, answer, or category matches the query.
  Future<List<FlashcardModel>> searchFlashcards(String query);

  /// Retrieves flashcards matching a specific category.
  Future<List<FlashcardModel>> getFlashcardsByCategory(String category);

  /// Retrieves flashcards marked as favorites.
  Future<List<FlashcardModel>> getFavoriteFlashcards();

  /// Retrieves a list of all distinct category names present in the database.
  Future<List<String>> getCategories();

  /// Retrieves flashcards filtered by category, favorite status, and sorted by a specific field.
  /// Supported values for [sortBy]: 'question', 'category', 'createdAt', 'difficulty'.
  Future<List<FlashcardModel>> getFlashcardsFiltered({
    String? category,
    bool? isFavorite,
    String? sortBy,
    bool sortAscending = true,
  });

  /// Retrieves today's completed study cards count.
  Future<int> getStudiedTodayCount();

  /// Logs a study activity (increments today's study count).
  Future<void> logStudyActivity();

  /// Retrieves study logs for the past specified number of days.
  Future<List<Map<String, dynamic>>> getStudyLogsForPastDays(int days);

  /// Resets the database, clearing all flashcards and study logs and re-seeding default cards.
  Future<void> resetDatabase();

  /// Gets the Host server's local network IP.
  Future<String> getHostIp(String baseUrl);

  /// Gets the current state of the Live Quiz session.
  Future<Map<String, dynamic>> getLiveQuizState(String baseUrl);

  /// Hosts a new Live Quiz session with the given settings.
  Future<void> hostLiveQuiz(String baseUrl, String category, int timerSeconds);

  /// Starts the hosted Live Quiz session.
  Future<void> startLiveQuiz(String baseUrl);

  /// Joins the Live Quiz session as a student nickname.
  Future<void> joinLiveQuiz(String baseUrl, String nickname);

  /// Submits the student's answer to the Live Quiz.
  Future<void> submitLiveAnswer(String baseUrl, String nickname, String answer);

  /// Advances the Live Quiz session to the next question.
  Future<void> nextLiveQuestion(String baseUrl);

  /// Ends the Live Quiz session.
  Future<void> endLiveQuiz(String baseUrl);
}

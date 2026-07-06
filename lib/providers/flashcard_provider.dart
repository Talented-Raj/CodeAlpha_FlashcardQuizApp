import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_model.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/flashcard_repository_impl.dart';
import '../database/database_helper.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardRepository _repository;

  List<FlashcardModel> _flashcards = [];
  List<String> _categories = [];
  List<FlashcardModel> _favoriteFlashcards = [];
  bool _isLoading = false;
  String _searchQuery = '';
  List<FlashcardModel> _searchResults = [];
  int _studiedTodayCount = 0;
  String _currentSortMode = 'date'; // 'date', 'category', 'alphabetical'

  FlashcardProvider({FlashcardRepository? repository})
      : _repository = repository ?? FlashcardRepositoryImpl() {
    loadData();
  }

  // Getters
  List<FlashcardModel> get flashcards {
    List<FlashcardModel> list = _searchQuery.isEmpty ? _flashcards : _searchResults;
    return _sortCardsList(list, _currentSortMode);
  }
  
  List<String> get categories => _categories;
  List<FlashcardModel> get favoriteFlashcards => _favoriteFlashcards;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int get studiedTodayCount => _studiedTodayCount;
  String get currentSortMode => _currentSortMode;

  // Stats Getters
  int get totalCount => _flashcards.length;
  int get favoriteCount => _favoriteFlashcards.length;

  List<FlashcardModel> _sortCardsList(List<FlashcardModel> list, String mode) {
    final sorted = List<FlashcardModel>.from(list);
    if (mode == 'alphabetical') {
      sorted.sort((a, b) => a.question.toLowerCase().compareTo(b.question.toLowerCase()));
    } else if (mode == 'category') {
      sorted.sort((a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()));
    } else {
      // Sort by Date (Newest first)
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  }

  void setSortMode(String mode) {
    _currentSortMode = mode;
    notifyListeners();
  }

  // Fetch all database states
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _flashcards = await _repository.getAllFlashcards();
      
      // Seed default categories if none exist in DB (just in case)
      _categories = await _repository.getCategories();
      if (_categories.isEmpty) {
        // Categories list has custom and default categories
        _categories = ['Programming', 'Mathematics', 'Science', 'History', 'English'];
      }
      
      _favoriteFlashcards = await _repository.getFavoriteFlashcards();
      if (_searchQuery.isNotEmpty) {
        _searchResults = await _repository.searchFlashcards(_searchQuery);
      }
      
      // Load today's study count
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toString().substring(0, 10);
      final todayLogs = await db.query('study_logs', where: 'date = ?', whereArgs: [todayStr]);
      _studiedTodayCount = todayLogs.isEmpty ? 0 : todayLogs.first['cards_count'] as int;
    } catch (e) {
      debugPrint('Error loading flashcards data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search
  Future<void> setSearchQuery(String query) async {
    _searchQuery = query;
    if (_searchQuery.isEmpty) {
      _searchResults = [];
    } else {
      try {
        _searchResults = await _repository.searchFlashcards(_searchQuery);
      } catch (e) {
        debugPrint('Error searching flashcards: $e');
      }
    }
    notifyListeners();
  }

  // CRUD Wrapper Operations
  Future<void> addFlashcard(
    String question,
    String answer,
    String category,
    String difficulty, {
    bool favorite = false,
  }) async {
    final newCard = FlashcardModel(
      question: question,
      answer: answer,
      category: category,
      difficulty: difficulty,
      favorite: favorite,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.insertFlashcard(newCard);
      await loadData();
    } catch (e) {
      debugPrint('Error adding flashcard: $e');
    }
  }

  Future<void> deleteFlashcard(int id) async {
    try {
      await _repository.deleteFlashcard(id);
      await loadData();
    } catch (e) {
      debugPrint('Error deleting flashcard ($id): $e');
    }
  }

  Future<void> updateFlashcard(FlashcardModel card) async {
    try {
      final updatedCard = card.copyWith(updatedAt: DateTime.now());
      await _repository.updateFlashcard(updatedCard);
      await loadData();
    } catch (e) {
      debugPrint('Error updating flashcard: $e');
    }
  }

  Future<void> toggleFavorite(FlashcardModel card) async {
    final updated = card.copyWith(favorite: !card.favorite);
    await updateFlashcard(updated);
  }

  // Log study session action (increments study counter)
  Future<void> logStudyActivity() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayStr = DateTime.now().toString().substring(0, 10);
      final logs = await db.query('study_logs', where: 'date = ?', whereArgs: [todayStr]);
      if (logs.isEmpty) {
        await db.insert('study_logs', {'date': todayStr, 'cards_count': 1});
      } else {
        final currentCount = logs.first['cards_count'] as int;
        await db.update('study_logs', {'cards_count': currentCount + 1}, where: 'date = ?', whereArgs: [todayStr]);
      }
      _studiedTodayCount++;
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging study activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudyLogsForPastDays(int days) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'study_logs',
        orderBy: 'date DESC',
        limit: days,
      );
      return maps;
    } catch (e) {
      debugPrint('Error getting study logs: $e');
      return [];
    }
  }

  Future<void> resetDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('Flashcards');
      await db.delete('study_logs');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('deck_pos_')) {
          await prefs.remove(key);
        }
      }

      // Re-seed default values
      final nowStr = DateTime.now().toIso8601String();
      final List<Map<String, dynamic>> defaultCards = [
        {
          'question': 'What is an Abstract Class?',
          'answer': 'A class that cannot be instantiated directly and serves as a blueprint for other subclasses. It can contain abstract methods (methods without a body) that must be implemented by subclasses.',
          'category': 'Programming',
          'difficulty': 'Medium',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is recursion?',
          'answer': 'A programming methodology where a function calls itself directly or indirectly to solve a larger problem by breaking it down into smaller, manageable subproblems.',
          'category': 'Programming',
          'difficulty': 'Medium',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is the difference between final and const in Dart?',
          'answer': '\'final\' variables are set once and initialized at runtime, whereas \'const\' variables are compile-time constants initialized at compilation time.',
          'category': 'Programming',
          'difficulty': 'Easy',
          'favorite': 1,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is the Pythagorean Theorem?',
          'answer': 'In a right-angled triangle, the square of the hypotenuse is equal to the sum of the squares of the other two sides (a² + b² = c²).',
          'category': 'Mathematics',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is a Prime Number?',
          'answer': 'A natural number greater than 1 that has no positive divisors other than 1 and itself (e.g., 2, 3, 5, 7, 11).',
          'category': 'Mathematics',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is Euler\'s Formula?',
          'answer': 'A mathematical formula in complex analysis: e^(iθ) = cos(θ) + i sin(θ). For θ = π, it yields the famous identity e^(iπ) + 1 = 0.',
          'category': 'Mathematics',
          'difficulty': 'Hard',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is Photosynthesis?',
          'answer': 'The biological process used by plants, algae, and some bacteria to transform solar light energy into chemical energy (glucose) using carbon dioxide and water.',
          'category': 'Science',
          'difficulty': 'Medium',
          'favorite': 1,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is the speed of light in a vacuum?',
          'answer': 'Approximately 299,792,458 meters per second (about 3.00 × 10⁸ m/s or 186,000 miles per second).',
          'category': 'Science',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is Newton\'s Third Law of Motion?',
          'answer': 'For every action, there is an equal and opposite reaction. It states that forces always occur in matched interaction pairs.',
          'category': 'Science',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'When did World War II begin?',
          'answer': 'September 1, 1939, with the invasion of Poland by Nazi Germany, prompting declarations of war by Britain and France.',
          'category': 'History',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What was the Magna Carta?',
          'answer': 'A royal charter of rights agreed to by King John of England in 1215, establishing the legal principle that everyone, including the monarch, is subject to the rule of law.',
          'category': 'History',
          'difficulty': 'Hard',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'Who was the first President of the United States?',
          'answer': 'George Washington, who served from 1789 to 1797 and is historically honored as the father of his country.',
          'category': 'History',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is a metaphor?',
          'answer': 'A figure of speech that makes a direct comparative reference between two unrelated things without using comparative words like \'like\' or \'as\' (e.g., \'Time is a thief\').',
          'category': 'English',
          'difficulty': 'Easy',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What does the word \'diligent\' mean?',
          'answer': 'Showing care, conscientiousness, and persistent, hard-working effort in carrying out one\'s work, assignments, or duties.',
          'category': 'English',
          'difficulty': 'Medium',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
        {
          'question': 'What is the difference between active and passive voice?',
          'answer': 'In active voice, the subject performs the action (e.g., \'The dog chased the cat\'). In passive voice, the subject receives the action (e.g., \'The cat was chased by the dog\').',
          'category': 'English',
          'difficulty': 'Medium',
          'favorite': 0,
          'createdAt': nowStr,
          'updatedAt': nowStr,
        },
      ];

      for (final card in defaultCards) {
        await db.insert('Flashcards', card);
      }
      
      await loadData();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }
}

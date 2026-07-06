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
  List<FlashcardModel> _dueFlashcards = [];
  List<FlashcardModel> _favoriteFlashcards = [];
  bool _isLoading = false;
  String _searchQuery = '';
  List<FlashcardModel> _searchResults = [];
  int _studiedTodayCount = 0;

  FlashcardProvider({FlashcardRepository? repository})
      : _repository = repository ?? FlashcardRepositoryImpl() {
    loadData();
  }

  // Getters
  List<FlashcardModel> get flashcards => _searchQuery.isEmpty ? _flashcards : _searchResults;
  List<String> get categories => _categories;
  List<FlashcardModel> get dueFlashcards => _dueFlashcards;
  List<FlashcardModel> get favoriteFlashcards => _favoriteFlashcards;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int get studiedTodayCount => _studiedTodayCount;

  // Stats Getters
  int get totalCount => _flashcards.length;
  int get dueCount => _dueFlashcards.length;
  int get favoriteCount => _favoriteFlashcards.length;

  Map<int, int> get boxDistribution {
    final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var card in _flashcards) {
      if (dist.containsKey(card.box)) {
        dist[card.box] = dist[card.box]! + 1;
      }
    }
    return dist;
  }

  // Fetch all database states
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _flashcards = await _repository.getAllFlashcards();
      _categories = await _repository.getCategories();
      _dueFlashcards = await _repository.getDueFlashcards();
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
    String front,
    String back,
    String category, {
    int box = 1,
    bool isFavorite = false,
  }) async {
    final newCard = FlashcardModel(
      front: front,
      back: back,
      category: category,
      box: box,
      isFavorite: isFavorite,
      nextReviewDate: DateTime.now(), // Due immediately when created
      createdAt: DateTime.now(),
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
      await _repository.updateFlashcard(card);
      await loadData();
    } catch (e) {
      debugPrint('Error updating flashcard: $e');
    }
  }

  Future<void> toggleFavorite(FlashcardModel card) async {
    final updated = card.copyWith(isFavorite: !card.isFavorite);
    await updateFlashcard(updated);
  }

  // Leitner Spaced Repetition Spacing Logic
  Future<void> reviewFlashcard(FlashcardModel card, bool wasCorrect) async {
    int nextBox = 1;
    int intervalDays = 1;

    if (wasCorrect) {
      nextBox = (card.box < 5) ? card.box + 1 : 5;
      switch (nextBox) {
        case 1:
          intervalDays = 1;
          break;
        case 2:
          intervalDays = 3;
          break;
        case 3:
          intervalDays = 7;
          break;
        case 4:
          intervalDays = 14;
          break;
        case 5:
          intervalDays = 30;
          break;
      }
    } else {
      // If incorrect, drop back to Box 1 for immediate restudy
      nextBox = 1;
      intervalDays = 1;
    }

    final updatedCard = card.copyWith(
      box: nextBox,
      nextReviewDate: DateTime.now().add(Duration(days: intervalDays)),
    );

    await logStudyActivity();
    await updateFlashcard(updatedCard);
  }

  // Study log helpers
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
      await db.delete('flashcards');
      await db.delete('study_logs');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('deck_pos_')) {
          await prefs.remove(key);
        }
      }
      
      await loadData();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }
}

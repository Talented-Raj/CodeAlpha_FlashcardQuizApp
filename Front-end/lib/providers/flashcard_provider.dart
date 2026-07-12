import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard_model.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/flashcard_repository_impl.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardRepository _repository;

  // Live Quiz State
  String _serverUrl = 'https://codealpha-flashcardquizapp-backend.onrender.com';
  String _hostIp = '';
  String _studentNickname = '';
  bool _isQuizHost = false;
  Map<String, dynamic>? _quizState;
  Timer? _quizSyncTimer;

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
      _studiedTodayCount = await _repository.getStudiedTodayCount();
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
      await _repository.logStudyActivity();
      _studiedTodayCount = await _repository.getStudiedTodayCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error logging study activity: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudyLogsForPastDays(int days) async {
    try {
      return await _repository.getStudyLogsForPastDays(days);
    } catch (e) {
      debugPrint('Error getting study logs: $e');
      return [];
    }
  }

  Future<void> resetDatabase() async {
    try {
      await _repository.resetDatabase();
      
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

  // --- Live Quiz Getters ---
  String get serverUrl => _serverUrl;
  String get hostIp => _hostIp;
  String get studentNickname => _studentNickname;
  bool get isQuizHost => _isQuizHost;
  Map<String, dynamic>? get quizState => _quizState;

  void updateServerUrl(String url) {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _serverUrl = url;
    notifyListeners();
  }

  Future<void> fetchHostIp() async {
    _hostIp = await _repository.getHostIp(_serverUrl);
    notifyListeners();
  }

  Future<void> hostQuiz(String category, int timerSeconds) async {
    _isQuizHost = true;
    _studentNickname = '';
    await _repository.hostLiveQuiz(_serverUrl, category, timerSeconds);
    await fetchHostIp();
    startSyncLoop();
  }

  Future<void> joinQuiz(String nickname) async {
    _isQuizHost = false;
    _studentNickname = nickname;
    await _repository.joinLiveQuiz(_serverUrl, nickname);
    startSyncLoop();
  }

  Future<void> startLiveQuiz() async {
    await _repository.startLiveQuiz(_serverUrl);
    await syncQuizState();
  }

  Future<void> submitLiveAnswer(String answer) async {
    await _repository.submitLiveAnswer(_serverUrl, _studentNickname, answer);
    await syncQuizState();
  }

  Future<void> nextLiveQuestion() async {
    await _repository.nextLiveQuestion(_serverUrl);
    await syncQuizState();
  }

  Future<void> endLiveQuiz() async {
    stopSyncLoop();
    try {
      await _repository.endLiveQuiz(_serverUrl);
    } catch (e) {
      debugPrint('Error ending quiz on server: $e');
    }
    _quizState = null;
    _isQuizHost = false;
    _studentNickname = '';
    notifyListeners();
  }

  Future<void> syncQuizState() async {
    try {
      final state = await _repository.getLiveQuizState(_serverUrl);
      _quizState = state;
      notifyListeners();

      if (state['status'] == 'ended' || state['status'] == 'idle') {
        stopSyncLoop();
      }
    } catch (e) {
      debugPrint('Sync Quiz State error: $e');
    }
  }

  void startSyncLoop() {
    stopSyncLoop();
    syncQuizState();
    _quizSyncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      syncQuizState();
    });
  }

  void stopSyncLoop() {
    _quizSyncTimer?.cancel();
    _quizSyncTimer = null;
  }

  @override
  void dispose() {
    stopSyncLoop();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_exceptions.dart';
import '../database/database_helper.dart';
import '../models/flashcard_model.dart';
import 'flashcard_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final DatabaseHelper? _dbHelper;
  static const String _baseUrl = 'https://codealpha-flashcardquizapp-backend.onrender.com/api';

  FlashcardRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = kIsWeb ? null : (dbHelper ?? DatabaseHelper.instance);

  // Helper for HTTP requests
  Future<dynamic> _get(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$path'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw NetworkException('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw NetworkException('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw NetworkException('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw NetworkException('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$path'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw NetworkException('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw NetworkException('Failed to connect to backend: $e');
    }
  }

  Future<dynamic> _delete(String path) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl$path'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw NetworkException('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw NetworkException('Failed to connect to backend: $e');
    }
  }

  @override
  Future<FlashcardModel> insertFlashcard(FlashcardModel card) async {
    if (kIsWeb) {
      final res = await _post('/flashcards', card.toMap());
      return FlashcardModel.fromMap(res);
    }

    try {
      final db = await _dbHelper!.database;
      final id = await db.insert(
        'Flashcards',
        card.toMap(),
      );
      return card.copyWith(id: id);
    } catch (e, stackTrace) {
      debugPrint('Error inserting flashcard: $e\n$stackTrace');
      throw DatabaseException('Failed to insert flashcard', e.toString());
    }
  }

  @override
  Future<FlashcardModel?> getFlashcardById(int id) async {
    if (kIsWeb) {
      final res = await _get('/flashcards/$id');
      if (res == null) return null;
      return FlashcardModel.fromMap(res);
    }

    try {
      final db = await _dbHelper!.database;
      final maps = await db.query(
        'Flashcards',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        return null;
      }
      return FlashcardModel.fromMap(maps.first);
    } catch (e, stackTrace) {
      debugPrint('Error fetching flashcard by id ($id): $e\n$stackTrace');
      throw DatabaseException('Failed to fetch flashcard by ID', e.toString());
    }
  }

  @override
  Future<List<FlashcardModel>> getAllFlashcards() async {
    if (kIsWeb) {
      final List res = await _get('/flashcards');
      return res.map((m) => FlashcardModel.fromMap(m)).toList();
    }

    try {
      final db = await _dbHelper!.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Flashcards',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => FlashcardModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching all flashcards: $e\n$stackTrace');
      throw DatabaseException('Failed to retrieve flashcards', e.toString());
    }
  }

  @override
  Future<int> updateFlashcard(FlashcardModel card) async {
    if (card.id == null) {
      throw DatabaseException('Cannot update a flashcard with no ID');
    }

    if (kIsWeb) {
      final res = await _put('/flashcards/${card.id}', card.toMap());
      return res['count'] as int? ?? 1;
    }

    try {
      final db = await _dbHelper!.database;
      final count = await db.update(
        'Flashcards',
        card.toMap(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
      if (count == 0) {
        throw FlashcardNotFoundException(card.id!);
      }
      return count;
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error updating flashcard (${card.id}): $e\n$stackTrace');
      throw DatabaseException('Failed to update flashcard', e.toString());
    }
  }

  @override
  Future<int> deleteFlashcard(int id) async {
    if (kIsWeb) {
      final res = await _delete('/flashcards/$id');
      return res['count'] as int? ?? 1;
    }

    try {
      final db = await _dbHelper!.database;
      final count = await db.delete(
        'Flashcards',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw FlashcardNotFoundException(id);
      }
      return count;
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error deleting flashcard ($id): $e\n$stackTrace');
      throw DatabaseException('Failed to delete flashcard', e.toString());
    }
  }

  @override
  Future<List<FlashcardModel>> searchFlashcards(String query) async {
    if (kIsWeb) {
      final List res = await _get('/flashcards/search?q=${Uri.encodeComponent(query)}');
      return res.map((m) => FlashcardModel.fromMap(m)).toList();
    }

    try {
      final db = await _dbHelper!.database;
      final dbQuery = '%$query%';
      final List<Map<String, dynamic>> maps = await db.query(
        'Flashcards',
        where: 'question LIKE ? OR answer LIKE ? OR category LIKE ?',
        whereArgs: [dbQuery, dbQuery, dbQuery],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => FlashcardModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      debugPrint('Error searching flashcards ($query): $e\n$stackTrace');
      throw DatabaseException('Failed during flashcard search', e.toString());
    }
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsByCategory(String category) async {
    if (kIsWeb) {
      final List res = await _get('/flashcards?category=${Uri.encodeComponent(category)}');
      return res.map((m) => FlashcardModel.fromMap(m)).toList();
    }

    try {
      final db = await _dbHelper!.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Flashcards',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => FlashcardModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching flashcards by category ($category): $e\n$stackTrace');
      throw DatabaseException('Failed to filter flashcards by category', e.toString());
    }
  }

  @override
  Future<List<FlashcardModel>> getFavoriteFlashcards() async {
    if (kIsWeb) {
      final List res = await _get('/flashcards?favorite=true');
      return res.map((m) => FlashcardModel.fromMap(m)).toList();
    }

    try {
      final db = await _dbHelper!.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'Flashcards',
        where: 'favorite = 1',
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => FlashcardModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching favorite flashcards: $e\n$stackTrace');
      throw DatabaseException('Failed to filter favorite flashcards', e.toString());
    }
  }

  @override
  Future<List<String>> getCategories() async {
    if (kIsWeb) {
      final List res = await _get('/categories');
      return res.cast<String>();
    }

    try {
      final db = await _dbHelper!.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT DISTINCT category FROM Flashcards ORDER BY category ASC',
      );

      return maps.map((row) => row['category'] as String).toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching categories: $e\n$stackTrace');
      throw DatabaseException('Failed to fetch distinct categories', e.toString());
    }
  }

  @override
  Future<List<FlashcardModel>> getFlashcardsFiltered({
    String? category,
    bool? isFavorite,
    String? sortBy,
    bool sortAscending = true,
  }) async {
    if (kIsWeb) {
      String query = '';
      if (category != null && category.trim().isNotEmpty) {
        query += '${query.isEmpty ? "?" : "&"}category=${Uri.encodeComponent(category)}';
      }
      if (isFavorite != null) {
        query += '${query.isEmpty ? "?" : "&"}favorite=$isFavorite';
      }
      if (sortBy != null) {
        query += '${query.isEmpty ? "?" : "&"}sortBy=$sortBy';
      }
      query += '${query.isEmpty ? "?" : "&"}sortAscending=$sortAscending';

      final List res = await _get('/flashcards$query');
      return res.map((m) => FlashcardModel.fromMap(m)).toList();
    }

    try {
      final db = await _dbHelper!.database;

      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];

      if (category != null && category.trim().isNotEmpty) {
        whereClauses.add('category = ?');
        whereArgs.add(category);
      }

      if (isFavorite != null) {
        whereClauses.add('favorite = ?');
        whereArgs.add(isFavorite ? 1 : 0);
      }

      final whereString = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

      String orderByColumn = 'createdAt';
      if (sortBy != null) {
        switch (sortBy) {
          case 'question':
            orderByColumn = 'question';
            break;
          case 'category':
            orderByColumn = 'category';
            break;
          case 'difficulty':
            orderByColumn = 'difficulty';
            break;
          case 'createdAt':
          default:
            orderByColumn = 'createdAt';
            break;
        }
      }

      final direction = sortAscending ? 'ASC' : 'DESC';
      final orderByString = '$orderByColumn $direction';

      final List<Map<String, dynamic>> maps = await db.query(
        'Flashcards',
        where: whereString,
        whereArgs: whereArgs,
        orderBy: orderByString,
      );

      return maps.map((map) => FlashcardModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching filtered flashcards: $e\n$stackTrace');
      throw DatabaseException('Failed to retrieve filtered/sorted flashcards', e.toString());
    }
  }

  @override
  Future<int> getStudiedTodayCount() async {
    if (kIsWeb) {
      final res = await _get('/study-logs/today');
      return res['count'] as int? ?? 0;
    }

    try {
      final db = await _dbHelper!.database;
      final todayStr = DateTime.now().toString().substring(0, 10);
      final todayLogs = await db.query('study_logs', where: 'date = ?', whereArgs: [todayStr]);
      return todayLogs.isEmpty ? 0 : todayLogs.first['cards_count'] as int;
    } catch (e) {
      debugPrint('Error getting studied today count: $e');
      return 0;
    }
  }

  @override
  Future<void> logStudyActivity() async {
    if (kIsWeb) {
      await _post('/study-logs/log', {});
      return;
    }

    try {
      final db = await _dbHelper!.database;
      final todayStr = DateTime.now().toString().substring(0, 10);
      final logs = await db.query('study_logs', where: 'date = ?', whereArgs: [todayStr]);
      if (logs.isEmpty) {
        await db.insert('study_logs', {'date': todayStr, 'cards_count': 1});
      } else {
        final currentCount = logs.first['cards_count'] as int;
        await db.update('study_logs', {'cards_count': currentCount + 1}, where: 'date = ?', whereArgs: [todayStr]);
      }
    } catch (e) {
      debugPrint('Error logging study activity: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStudyLogsForPastDays(int days) async {
    if (kIsWeb) {
      final List res = await _get('/study-logs?days=$days');
      return res.cast<Map<String, dynamic>>();
    }

    try {
      final db = await _dbHelper!.database;
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

  @override
  Future<void> resetDatabase() async {
    if (kIsWeb) {
      await _post('/reset', {});
      return;
    }

    try {
      final db = await _dbHelper!.database;
      await db.delete('Flashcards');
      await db.delete('study_logs');

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
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }

  @override
  Future<String> getHostIp(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/host-ip'));
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        return res['ip'] as String? ?? 'localhost';
      }
      return 'localhost';
    } catch (e) {
      debugPrint('Error getting host IP: $e');
      return 'localhost';
    }
  }

  @override
  Future<Map<String, dynamic>> getLiveQuizState(String baseUrl) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/quiz/state'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw NetworkException('Failed to get quiz state: ${response.statusCode}');
    } catch (e) {
      throw NetworkException('Failed to connect to server: $e');
    }
  }

  @override
  Future<void> hostLiveQuiz(String baseUrl, String category, int timerSeconds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/quiz/host'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'timeLimit': timerSeconds,
        }),
      );
      if (response.statusCode != 200) {
        final err = json.decode(response.body);
        throw NetworkException(err['error'] ?? 'Failed to host quiz');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> startLiveQuiz(String baseUrl) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/quiz/start'));
      if (response.statusCode != 200) {
        final err = json.decode(response.body);
        throw NetworkException(err['error'] ?? 'Failed to start quiz');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> joinLiveQuiz(String baseUrl, String nickname) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/quiz/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nickname': nickname}),
      );
      if (response.statusCode != 200) {
        final err = json.decode(response.body);
        throw NetworkException(err['error'] ?? 'Failed to join quiz');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> submitLiveAnswer(String baseUrl, String nickname, String answer) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/quiz/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nickname': nickname,
          'answer': answer,
        }),
      );
      if (response.statusCode != 200) {
        final err = json.decode(response.body);
        throw NetworkException(err['error'] ?? 'Failed to submit answer');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> nextLiveQuestion(String baseUrl) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/quiz/next'));
      if (response.statusCode != 200) {
        final err = json.decode(response.body);
        throw NetworkException(err['error'] ?? 'Failed to advance quiz');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> endLiveQuiz(String baseUrl) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/api/quiz/end'));
      if (response.statusCode != 200) {
        final err = json.decode(response.body);
        throw NetworkException(err['error'] ?? 'Failed to end quiz');
      }
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }
}

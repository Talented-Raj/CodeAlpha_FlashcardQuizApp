import 'package:flutter/foundation.dart';
import '../utils/app_exceptions.dart';
import '../database/database_helper.dart';
import '../models/flashcard_model.dart';
import 'flashcard_repository.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final DatabaseHelper _dbHelper;

  FlashcardRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<FlashcardModel> insertFlashcard(FlashcardModel card) async {
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;
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
    try {
      final db = await _dbHelper.database;

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

      // Map dynamic sort arguments to database columns safely
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
}

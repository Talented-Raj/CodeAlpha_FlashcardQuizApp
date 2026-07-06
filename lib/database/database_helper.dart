import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Flashcards Table
    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        category TEXT NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0, -- 0 = false, 1 = true
        box INTEGER NOT NULL DEFAULT 1,         -- Leitner box number (1-5)
        next_review_date TEXT NOT NULL,         -- ISO 8601 string
        created_at TEXT NOT NULL                -- ISO 8601 string
      )
    ''');

    // Create Study Logs Table
    await db.execute('''
      CREATE TABLE study_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL, -- YYYY-MM-DD format
        cards_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE study_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT UNIQUE NOT NULL, -- YYYY-MM-DD format
          cards_count INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}

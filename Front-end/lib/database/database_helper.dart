import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../models/flashcard_model.dart';

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
      version: 3, // Increment version for new schema migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Flashcards Table matching requested fields
    await db.execute('''
      CREATE TABLE Flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0, -- 0 = false, 1 = true
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create Study Logs Table for Daily Study Counter
    await db.execute('''
      CREATE TABLE study_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT UNIQUE NOT NULL, -- YYYY-MM-DD format
        cards_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Pre-seed database with default internship decks
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Recreate tables to apply clean new schema
      await db.execute('DROP TABLE IF EXISTS flashcards');
      await db.execute('DROP TABLE IF EXISTS Flashcards');
      await db.execute('DROP TABLE IF EXISTS study_logs');
      await _createDB(db, newVersion);
    }
  }

  Future<void> _seedDatabase(Database db) async {
    final nowStr = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> defaultCards = [
      // Programming
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
      // Mathematics
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
      // Science
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
      // History
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
      // English
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
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'board_settings.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE board_settings(
        board_name TEXT PRIMARY KEY,
        cut_line INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Set initial cutLine values
    await db.insert(
      'board_settings',
      {'board_name': 'clien', 'cut_line': 1000},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'board_settings',
      {'board_name': 'ddanzi', 'cut_line': 200},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setCutLine(String boardName, int cutLine) async {
    final db = await database;
    await db.insert(
      'board_settings',
      {
        'board_name': boardName,
        'cut_line': cutLine,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getCutLine(String boardName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'board_settings',
      where: 'board_name = ?',
      whereArgs: [boardName],
    );

    if (maps.isEmpty) {
      return 0;
    }
    return maps.first['cut_line'] as int;
  }

  Future<Map<String, int>> getAllCutLines() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('board_settings');
    
    return Map.fromEntries(
      maps.map((map) => MapEntry(
        map['board_name'] as String,
        map['cut_line'] as int,
      )),
    );
  }
} 
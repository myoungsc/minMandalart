import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/goal_model.dart';

class SQLiteHelper {
  static final SQLiteHelper instance = SQLiteHelper._init();
  static Database? _database;

  SQLiteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mandalart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE mandalart_boards (
        id $idType,
        center_goal $textType,
        description $textTypeNullable,
        created_at $textType,
        updated_at $textTypeNullable
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id $idType,
        title $textType,
        description $textTypeNullable,
        parent_id $intType,
        position $intType,
        is_completed $intType,
        progress $intType,
        created_at $textType,
        updated_at $textTypeNullable,
        FOREIGN KEY (parent_id) REFERENCES mandalart_boards (id) ON DELETE CASCADE
      )
    ''');
  }

  // MandalartBoard CRUD Operations

  Future<int> createMandalartBoard(MandalartBoard board) async {
    final db = await database;
    return await db.insert('mandalart_boards', board.toMap());
  }

  Future<MandalartBoard?> readMandalartBoard(int id) async {
    final db = await database;
    final maps = await db.query(
      'mandalart_boards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final goals = await readGoalsByBoardId(id);
      return MandalartBoard.fromMap(maps.first, goals: goals);
    }
    return null;
  }

  Future<List<MandalartBoard>> readAllMandalartBoards() async {
    final db = await database;
    const orderBy = 'created_at DESC';
    final result = await db.query('mandalart_boards', orderBy: orderBy);

    final boards = <MandalartBoard>[];
    for (final map in result) {
      final boardId = map['id'] as int;
      final goals = await readGoalsByBoardId(boardId);
      boards.add(MandalartBoard.fromMap(map, goals: goals));
    }

    return boards;
  }

  Future<int> updateMandalartBoard(MandalartBoard board) async {
    final db = await database;
    return await db.update(
      'mandalart_boards',
      board.toMap(),
      where: 'id = ?',
      whereArgs: [board.id],
    );
  }

  Future<int> deleteMandalartBoard(int id) async {
    final db = await database;
    return await db.delete(
      'mandalart_boards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Goal CRUD Operations

  Future<int> createGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  Future<Goal?> readGoal(int id) async {
    final db = await database;
    final maps = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Goal.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Goal>> readGoalsByBoardId(int boardId) async {
    final db = await database;
    const orderBy = 'position ASC';
    final result = await db.query(
      'goals',
      where: 'parent_id = ?',
      whereArgs: [boardId],
      orderBy: orderBy,
    );

    return result.map((map) => Goal.fromMap(map)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

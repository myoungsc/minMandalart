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
      version: 2,
      // SQLite는 연결마다 외래 키가 꺼져 있어 켜야 ON DELETE CASCADE가 동작함
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await migrateToV2(db);
      },
    );
  }

  /// 예전 버전에서 남은 데이터 정리: 삭제된 보드의 목표, 중복 칸 제거 후 빠진 칸(0~7) 채우기
  static Future<void> migrateToV2(DatabaseExecutor db) async {
    await db.execute(
      'DELETE FROM goals WHERE parent_id NOT IN (SELECT id FROM mandalart_boards)',
    );
    await db.execute(
      'DELETE FROM goals WHERE id NOT IN (SELECT MAX(id) FROM goals GROUP BY parent_id, position)',
    );
    await db.execute('''
      WITH RECURSIVE positions(position) AS (
        SELECT 0 UNION ALL SELECT position + 1 FROM positions WHERE position < 7
      )
      INSERT INTO goals (title, parent_id, position, is_completed, progress, created_at)
      SELECT '', b.id, p.position, 0, 0, b.created_at
      FROM mandalart_boards b CROSS JOIN positions p
      WHERE NOT EXISTS (
        SELECT 1 FROM goals g WHERE g.parent_id = b.id AND g.position = p.position
      )
    ''');
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

  /// 보드와 빈 칸 8개를 함께 만든다. 중간에 실패하면 전부 취소된다.
  Future<int> createBoardWithEmptyGoals(MandalartBoard board) async {
    final db = await database;
    return db.transaction((txn) async {
      final boardId = await txn.insert('mandalart_boards', board.toMap());
      for (int position = 0; position < 8; position++) {
        final goal = Goal(
          title: '',
          parentId: boardId,
          position: position,
          createdAt: board.createdAt,
        );
        await txn.insert('goals', goal.toMap());
      }
      return boardId;
    });
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

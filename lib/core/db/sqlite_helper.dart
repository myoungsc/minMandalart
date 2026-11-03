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
      version: 3,
      // SQLite는 연결마다 외래 키가 꺼져 있어 켜야 ON DELETE CASCADE가 동작함
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: upgrade,
    );
  }

  static Future<void> upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) await migrateToV2(db);
    if (oldVersion < 3) await _createChecklistTable(db);
  }

  static Future<void> _createChecklistTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE checklist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        position INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (goal_id) REFERENCES goals (id) ON DELETE CASCADE
      )
    ''');
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

    await _createChecklistTable(db);
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

    if (maps.isEmpty) return null;

    final items = await db.rawQuery(
      '''
      SELECT c.* FROM checklist_items c
      JOIN goals g ON g.id = c.goal_id
      WHERE g.parent_id = ?
      ORDER BY c.position, c.id
      ''',
      [id],
    );
    final itemsByGoal = <int, List<ChecklistItem>>{};
    for (final map in items) {
      final item = ChecklistItem.fromMap(map);
      (itemsByGoal[item.goalId] ??= []).add(item);
    }

    final goals = await readGoalsByBoardId(id);
    return MandalartBoard.fromMap(
      maps.first,
      goals: [
        for (final goal in goals)
          goal.copyWith(checklistItems: itemsByGoal[goal.id] ?? const []),
      ],
    );
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

  /// 칸의 내용과 체크리스트를 모두 지워 빈 칸으로 되돌린다.
  Future<void> clearGoal(int goalId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'checklist_items',
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );
      await txn.update(
        'goals',
        {
          'title': '',
          'description': null,
          'progress': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [goalId],
      );
    });
  }

  /// 체크리스트가 없는 칸만 완료 표시할 수 있다. 있으면 진행률은 항목으로 계산된다.
  Future<void> setGoalCompleted(int goalId, bool isCompleted) async {
    final db = await database;
    await db.rawUpdate(
      '''
      UPDATE goals SET progress = ?, updated_at = ?
      WHERE id = ?
        AND NOT EXISTS (SELECT 1 FROM checklist_items WHERE goal_id = ?)
      ''',
      [isCompleted ? 100 : 0, DateTime.now().toIso8601String(), goalId, goalId],
    );
  }

  // Checklist CRUD Operations: 변경할 때마다 칸의 진행률을 같은 트랜잭션에서 다시 계산한다.

  Future<int> addChecklistItem(int goalId, String title) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.rawInsert(
        '''
        INSERT INTO checklist_items (goal_id, title, position, created_at)
        SELECT ?, ?, COALESCE(MAX(position) + 1, 0), ?
        FROM checklist_items WHERE goal_id = ?
        ''',
        [goalId, title, DateTime.now().toIso8601String(), goalId],
      );
      await _syncGoalProgress(txn, goalId);
      return id;
    });
  }

  Future<void> setChecklistItemDone(ChecklistItem item, bool isDone) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'checklist_items',
        {'is_done': isDone ? 1 : 0},
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await _syncGoalProgress(txn, item.goalId);
    });
  }

  Future<void> deleteChecklistItem(ChecklistItem item) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'checklist_items',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      await _syncGoalProgress(txn, item.goalId);
    });
  }

  /// 완료 항목 수 / 전체 항목 수. 항목이 하나도 없으면 0으로 되돌린다.
  Future<void> _syncGoalProgress(DatabaseExecutor db, int goalId) async {
    await db.rawUpdate(
      '''
      UPDATE goals SET
        progress = COALESCE(
          (SELECT SUM(is_done) * 100 / COUNT(*) FROM checklist_items WHERE goal_id = ?),
          0
        ),
        updated_at = ?
      WHERE id = ?
      ''',
      [goalId, DateTime.now().toIso8601String(), goalId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

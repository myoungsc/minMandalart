import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/db/sqlite_helper.dart';
import 'package:mandalart/core/providers/goal_provider.dart';
import 'package:mandalart/models/goal_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // sqflite_ffi 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SQLiteHelper MandalartBoard CRUD 테스트', () {
    late SQLiteHelper helper;

    setUp(() async {
      helper = SQLiteHelper.instance;
    });

    test('MandalartBoard 생성 테스트', () async {
      final now = DateTime.now();
      final board = MandalartBoard(
        centerGoal: '테스트 중앙 목표',
        description: '테스트 설명',
        createdAt: now,
      );

      final id = await helper.createMandalartBoard(board);

      expect(id, greaterThan(0));
    });

    test('MandalartBoard 읽기 테스트', () async {
      final now = DateTime.now();
      final board = MandalartBoard(
        centerGoal: '읽기 테스트 목표',
        description: '읽기 테스트 설명',
        createdAt: now,
      );

      final id = await helper.createMandalartBoard(board);
      final readBoard = await helper.readMandalartBoard(id);

      expect(readBoard, isNotNull);
      expect(readBoard?.centerGoal, '읽기 테스트 목표');
      expect(readBoard?.description, '읽기 테스트 설명');
    });

    test('존재하지 않는 MandalartBoard 읽기 테스트', () async {
      final readBoard = await helper.readMandalartBoard(99999);

      expect(readBoard, isNull);
    });

    test('모든 MandalartBoard 읽기 테스트', () async {
      final now = DateTime.now();

      // 여러 개의 보드 생성
      await helper.createMandalartBoard(MandalartBoard(
        centerGoal: '목표 1',
        createdAt: now,
      ));
      await helper.createMandalartBoard(MandalartBoard(
        centerGoal: '목표 2',
        createdAt: now.add(const Duration(seconds: 1)),
      ));
      await helper.createMandalartBoard(MandalartBoard(
        centerGoal: '목표 3',
        createdAt: now.add(const Duration(seconds: 2)),
      ));

      final boards = await helper.readAllMandalartBoards();

      expect(boards.length, greaterThanOrEqualTo(3));
      // 최신순 정렬 확인 (created_at DESC)
      expect(boards.first.centerGoal, '목표 3');
    });

    test('MandalartBoard 업데이트 테스트', () async {
      final now = DateTime.now();
      final board = MandalartBoard(
        centerGoal: '원본 목표',
        description: '원본 설명',
        createdAt: now,
      );

      final id = await helper.createMandalartBoard(board);
      final readBoard = await helper.readMandalartBoard(id);

      final updatedBoard = readBoard!.copyWith(
        centerGoal: '수정된 목표',
        description: '수정된 설명',
        updatedAt: DateTime.now(),
      );

      final updateCount = await helper.updateMandalartBoard(updatedBoard);
      final finalBoard = await helper.readMandalartBoard(id);

      expect(updateCount, 1);
      expect(finalBoard?.centerGoal, '수정된 목표');
      expect(finalBoard?.description, '수정된 설명');
    });

    test('MandalartBoard 삭제 테스트', () async {
      final now = DateTime.now();
      final board = MandalartBoard(
        centerGoal: '삭제할 목표',
        createdAt: now,
      );

      final id = await helper.createMandalartBoard(board);
      expect(await helper.readMandalartBoard(id), isNotNull);

      final deleteCount = await helper.deleteMandalartBoard(id);
      final deletedBoard = await helper.readMandalartBoard(id);

      expect(deleteCount, 1);
      expect(deletedBoard, isNull);
    });
  });

  group('SQLiteHelper Goal CRUD 테스트', () {
    late SQLiteHelper helper;
    late int boardId;

    setUp(() async {
      helper = SQLiteHelper.instance;

      // 테스트용 보드 생성
      final board = MandalartBoard(
        centerGoal: '테스트 보드',
        createdAt: DateTime.now(),
      );
      boardId = await helper.createMandalartBoard(board);
    });

    test('Goal 생성 테스트', () async {
      final now = DateTime.now();
      final goal = Goal(
        title: '테스트 목표',
        description: '테스트 설명',
        parentId: boardId,
        position: 0,
        progress: 0,
        createdAt: now,
      );

      final id = await helper.createGoal(goal);

      expect(id, greaterThan(0));
    });

    test('Goal 읽기 테스트', () async {
      final now = DateTime.now();
      final goal = Goal(
        title: '읽기 테스트',
        description: '읽기 설명',
        parentId: boardId,
        position: 1,
        progress: 50,
        createdAt: now,
      );

      final id = await helper.createGoal(goal);
      final readGoal = await helper.readGoal(id);

      expect(readGoal, isNotNull);
      expect(readGoal?.title, '읽기 테스트');
      expect(readGoal?.description, '읽기 설명');
      expect(readGoal?.position, 1);
      expect(readGoal?.progress, 50);
    });

    test('존재하지 않는 Goal 읽기 테스트', () async {
      final readGoal = await helper.readGoal(99999);

      expect(readGoal, isNull);
    });

    test('boardId로 Goal 목록 읽기 테스트', () async {
      final now = DateTime.now();

      // 여러 개의 목표 생성
      await helper.createGoal(Goal(
        title: '목표 1',
        parentId: boardId,
        position: 2,
        createdAt: now,
      ));
      await helper.createGoal(Goal(
        title: '목표 2',
        parentId: boardId,
        position: 0,
        createdAt: now,
      ));
      await helper.createGoal(Goal(
        title: '목표 3',
        parentId: boardId,
        position: 1,
        createdAt: now,
      ));

      final goals = await helper.readGoalsByBoardId(boardId);

      expect(goals.length, 3);
      // position으로 정렬되어야 함
      expect(goals[0].position, 0);
      expect(goals[1].position, 1);
      expect(goals[2].position, 2);
      expect(goals[0].title, '목표 2');
      expect(goals[1].title, '목표 3');
      expect(goals[2].title, '목표 1');
    });

    test('Goal 업데이트 테스트', () async {
      final now = DateTime.now();
      final goal = Goal(
        title: '원본 제목',
        description: '원본 설명',
        parentId: boardId,
        position: 0,
        progress: 0,
        createdAt: now,
      );

      final id = await helper.createGoal(goal);
      final readGoal = await helper.readGoal(id);

      final updatedGoal = readGoal!.copyWith(
        title: '수정된 제목',
        description: '수정된 설명',
        progress: 75,
        updatedAt: DateTime.now(),
      );

      final updateCount = await helper.updateGoal(updatedGoal);
      final finalGoal = await helper.readGoal(id);

      expect(updateCount, 1);
      expect(finalGoal?.title, '수정된 제목');
      expect(finalGoal?.description, '수정된 설명');
      expect(finalGoal?.progress, 75);
    });

    test('Goal 삭제 테스트', () async {
      final now = DateTime.now();
      final goal = Goal(
        title: '삭제할 목표',
        parentId: boardId,
        position: 0,
        createdAt: now,
      );

      final id = await helper.createGoal(goal);
      expect(await helper.readGoal(id), isNotNull);

      final deleteCount = await helper.deleteGoal(id);
      final deletedGoal = await helper.readGoal(id);

      expect(deleteCount, 1);
      expect(deletedGoal, isNull);
    });

    test('MandalartBoard 삭제 테스트 with Goals', () async {
      final now = DateTime.now();

      // Goal 생성
      final goal1 = Goal(
        title: 'Cascade 테스트 1',
        parentId: boardId,
        position: 0,
        createdAt: now,
      );
      final goal2 = Goal(
        title: 'Cascade 테스트 2',
        parentId: boardId,
        position: 1,
        createdAt: now,
      );

      await helper.createGoal(goal1);
      await helper.createGoal(goal2);

      final goalsBefore = await helper.readGoalsByBoardId(boardId);
      expect(goalsBefore.length, 2);

      // Board 삭제
      final deleteCount = await helper.deleteMandalartBoard(boardId);
      expect(deleteCount, 1);

      // Board가 삭제되었는지 확인
      final deletedBoard = await helper.readMandalartBoard(boardId);
      expect(deletedBoard, isNull);

      // 하위 Goal도 함께 삭제되었는지 확인
      expect(await helper.readGoalsByBoardId(boardId), isEmpty);
    });
  });

  group('SQLiteHelper 통합 테스트', () {
    late SQLiteHelper helper;

    setUp(() async {
      helper = SQLiteHelper.instance;
    });

    test('MandalartBoard와 Goal을 함께 생성하고 조회 테스트', () async {
      final now = DateTime.now();

      // Board 생성
      final board = MandalartBoard(
        centerGoal: '통합 테스트 목표',
        description: '통합 테스트 설명',
        createdAt: now,
      );
      final boardId = await helper.createMandalartBoard(board);

      // Goal 8개 생성 (만다라트는 8개의 세부 목표)
      for (int i = 0; i < 8; i++) {
        await helper.createGoal(Goal(
          title: '세부 목표 $i',
          parentId: boardId,
          position: i,
          progress: i * 10,
          createdAt: now,
        ));
      }

      // Board와 Goal 함께 조회
      final readBoard = await helper.readMandalartBoard(boardId);

      expect(readBoard, isNotNull);
      expect(readBoard?.centerGoal, '통합 테스트 목표');
      expect(readBoard?.subGoals.length, 8);
      expect(readBoard?.subGoals[0].title, '세부 목표 0');
      expect(readBoard?.subGoals[7].title, '세부 목표 7');

      // overallProgress 계산 테스트
      // (0 + 10 + 20 + 30 + 40 + 50 + 60 + 70) / 8 = 280 / 8 = 35
      expect(readBoard?.overallProgress, 35);
    });
  });

  group('보드 생성과 마이그레이션', () {
    test('createBoardWithEmptyGoals는 빈 칸 8개를 함께 만든다', () async {
      final helper = SQLiteHelper.instance;
      final id = await helper.createBoardWithEmptyGoals(
        MandalartBoard(centerGoal: '트랜잭션', createdAt: DateTime.now()),
      );

      final goals = await helper.readGoalsByBoardId(id);
      expect(goals.map((g) => g.position), [0, 1, 2, 3, 4, 5, 6, 7]);
      expect(goals.every((g) => g.title.isEmpty), isTrue);
    });

    test('migrateToV2는 고아, 중복을 지우고 빠진 칸을 채운다', () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        'CREATE TABLE mandalart_boards (id INTEGER PRIMARY KEY AUTOINCREMENT, center_goal TEXT NOT NULL, description TEXT, created_at TEXT NOT NULL, updated_at TEXT)',
      );
      await db.execute(
        'CREATE TABLE goals (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT, parent_id INTEGER NOT NULL, position INTEGER NOT NULL, is_completed INTEGER NOT NULL, progress INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT)',
      );
      await db.insert('mandalart_boards', {
        'id': 1,
        'center_goal': '보드',
        'created_at': '2026-01-01T00:00:00.000',
      });
      Future<void> addGoal(String title, int parentId, int position) =>
          db.insert('goals', {
            'title': title,
            'parent_id': parentId,
            'position': position,
            'is_completed': 0,
            'progress': 0,
            'created_at': '2026-01-01T00:00:00.000',
          });
      await addGoal('고아', 99, 0);
      await addGoal('예전 중복', 1, 3);
      await addGoal('최신', 1, 3);

      await SQLiteHelper.migrateToV2(db);

      final rows = await db.query('goals', orderBy: 'position');
      expect(rows.map((r) => r['parent_id']).toSet(), {1});
      expect(rows.map((r) => r['position']), [0, 1, 2, 3, 4, 5, 6, 7]);
      expect(rows.map((r) => r['title']).where((t) => t != ''), ['최신']);
    });
  });

  group('체크리스트', () {
    final helper = SQLiteHelper.instance;
    late int boardId;
    late Goal goal;

    Future<Goal> reload() async {
      final board = await helper.readMandalartBoard(boardId);
      return board!.subGoals.firstWhere((g) => g.id == goal.id);
    }

    setUp(() async {
      boardId = await helper.createBoardWithEmptyGoals(
        MandalartBoard(centerGoal: '체크리스트', createdAt: DateTime.now()),
      );
      goal = (await helper.readMandalartBoard(boardId))!.subGoals.first;
    });

    test('항목은 추가한 순서로 읽고, 다른 칸과 섞이지 않는다', () async {
      await helper.addChecklistItem(goal.id!, '첫째');
      await helper.addChecklistItem(goal.id!, '둘째');

      final board = await helper.readMandalartBoard(boardId);
      expect(board!.subGoals[0].checklistItems.map((i) => i.title), ['첫째', '둘째']);
      expect(board.subGoals[0].checklistItems.map((i) => i.position), [0, 1]);
      expect(board.subGoals[1].checklistItems, isEmpty);
    });

    test('진행률은 완료 항목 비율로 계산되고, 항목이 없어지면 0이 된다', () async {
      await helper.addChecklistItem(goal.id!, 'A');
      await helper.addChecklistItem(goal.id!, 'B');
      await helper.addChecklistItem(goal.id!, 'C');
      expect((await reload()).progress, 0);

      var items = (await reload()).checklistItems;
      await helper.setChecklistItemDone(items[0], true);
      expect((await reload()).progress, 33);

      await helper.setChecklistItemDone(items[1], true);
      await helper.setChecklistItemDone(items[2], true);
      expect((await reload()).progress, 100);

      await helper.setChecklistItemDone(items[2], false);
      expect((await reload()).progress, 66);

      await helper.deleteChecklistItem(items[2]);
      expect((await reload()).progress, 100);

      for (final item in (await reload()).checklistItems) {
        await helper.deleteChecklistItem(item);
      }
      expect((await reload()).progress, 0);
    });

    test('완료 토글은 체크리스트가 없는 칸에만 적용된다', () async {
      await helper.setGoalCompleted(goal.id!, true);
      expect((await reload()).progress, 100);
      await helper.setGoalCompleted(goal.id!, false);
      expect((await reload()).progress, 0);

      await helper.addChecklistItem(goal.id!, 'A');
      await helper.setGoalCompleted(goal.id!, true);
      expect((await reload()).progress, 0);
    });

    test('항목을 처음 추가하면 기존 수동 진행률을 대체한다', () async {
      await helper.updateGoal(goal.copyWith(title: '기존', progress: 40));
      expect((await reload()).progress, 40);

      await helper.addChecklistItem(goal.id!, 'A');
      expect((await reload()).progress, 0);
    });

    test('칸 비우기는 내용과 체크리스트를 함께 지운다', () async {
      await helper.updateGoal(
        goal.copyWith(title: '제목', description: '설명', progress: 100),
      );
      await helper.addChecklistItem(goal.id!, 'A');

      await helper.clearGoal(goal.id!);

      final cleared = await reload();
      expect(cleared.title, '');
      expect(cleared.description, isNull);
      expect(cleared.progress, 0);
      expect(cleared.checklistItems, isEmpty);
    });

    test('보드를 삭제하면 항목도 함께 삭제된다', () async {
      final itemId = await helper.addChecklistItem(goal.id!, 'A');

      await helper.deleteMandalartBoard(boardId);

      final db = await helper.database;
      expect(
        await db.query('checklist_items', where: 'id = ?', whereArgs: [itemId]),
        isEmpty,
      );
    });

    test('Notifier는 저장 후 현재 보드와 홈 목록을 함께 갱신한다', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(currentBoardProvider.notifier);
      await notifier.loadBoard(boardId);
      final boards = container.read(mandalartBoardsProvider.notifier);
      await boards.loadBoards();

      await notifier.setGoalCompleted(goal.id!, true);
      await notifier.addChecklistItem(goal.id!, 'A');
      var current = container.read(currentBoardProvider)!.subGoals.first;
      expect(current.checklistItems.single.title, 'A');
      expect(current.progress, 0);

      await notifier.setChecklistItemDone(current.checklistItems.single, true);
      final listed = container
          .read(mandalartBoardsProvider)
          .requireValue
          .firstWhere((b) => b.id == boardId);
      expect(listed.subGoals.first.progress, 100);
    });

    test('v1 DB를 v3로 올리면 기존 목표가 유지되고 체크리스트를 쓸 수 있다', () async {
      final dir = await Directory.systemTemp.createTemp('mandalart');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/upgrade.db';

      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE mandalart_boards (id INTEGER PRIMARY KEY AUTOINCREMENT, center_goal TEXT NOT NULL, description TEXT, created_at TEXT NOT NULL, updated_at TEXT)',
            );
            await db.execute(
              'CREATE TABLE goals (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, description TEXT, parent_id INTEGER NOT NULL, position INTEGER NOT NULL, is_completed INTEGER NOT NULL, progress INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT, FOREIGN KEY (parent_id) REFERENCES mandalart_boards (id) ON DELETE CASCADE)',
            );
            await db.insert('mandalart_boards', {
              'id': 1,
              'center_goal': '보드',
              'created_at': '2026-01-01T00:00:00.000',
            });
            await db.insert('goals', {
              'title': '기존 목표',
              'parent_id': 1,
              'position': 0,
              'is_completed': 0,
              'progress': 40,
              'created_at': '2026-01-01T00:00:00.000',
            });
          },
        ),
      );
      await v1.close();

      final v3 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 3, onUpgrade: SQLiteHelper.upgrade),
      );
      addTearDown(v3.close);

      expect(await v3.getVersion(), 3);
      final goals = await v3.query('goals', orderBy: 'position');
      expect(goals.length, 8);
      expect(goals.first['title'], '기존 목표');
      expect(goals.first['progress'], 40);
      expect(await v3.query('checklist_items'), isEmpty);
    });
  });
}

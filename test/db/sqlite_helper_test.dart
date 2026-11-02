import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/db/sqlite_helper.dart';
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
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/models/goal_model.dart';

void main() {
  group('Goal 모델 테스트', () {
    test('Goal 객체 생성 테스트', () {
      final now = DateTime.now();
      final goal = Goal(
        id: 1,
        title: '테스트 목표',
        description: '테스트 설명',
        parentId: 1,
        position: 0,
        isCompleted: false,
        progress: 50,
        createdAt: now,
      );

      expect(goal.id, 1);
      expect(goal.title, '테스트 목표');
      expect(goal.description, '테스트 설명');
      expect(goal.parentId, 1);
      expect(goal.position, 0);
      expect(goal.isCompleted, false);
      expect(goal.progress, 50);
      expect(goal.createdAt, now);
    });

    test('Goal toMap 변환 테스트', () {
      final now = DateTime.now();
      final goal = Goal(
        id: 1,
        title: '테스트 목표',
        description: '테스트 설명',
        parentId: 1,
        position: 0,
        isCompleted: true,
        progress: 75,
        createdAt: now,
        updatedAt: now,
      );

      final map = goal.toMap();

      expect(map['id'], 1);
      expect(map['title'], '테스트 목표');
      expect(map['description'], '테스트 설명');
      expect(map['parent_id'], 1);
      expect(map['position'], 0);
      expect(map['is_completed'], 1);
      expect(map['progress'], 75);
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('Goal fromMap 변환 테스트', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'title': '테스트 목표',
        'description': '테스트 설명',
        'parent_id': 1,
        'position': 0,
        'is_completed': 1,
        'progress': 75,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final goal = Goal.fromMap(map);

      expect(goal.id, 1);
      expect(goal.title, '테스트 목표');
      expect(goal.description, '테스트 설명');
      expect(goal.parentId, 1);
      expect(goal.position, 0);
      expect(goal.isCompleted, true);
      expect(goal.progress, 75);
    });

    test('Goal copyWith 테스트', () {
      final now = DateTime.now();
      final goal = Goal(
        id: 1,
        title: '테스트 목표',
        description: '테스트 설명',
        parentId: 1,
        position: 0,
        progress: 50,
        createdAt: now,
      );

      final updatedGoal = goal.copyWith(title: '수정된 목표', progress: 100);

      expect(updatedGoal.title, '수정된 목표');
      expect(updatedGoal.progress, 100);
      expect(updatedGoal.id, 1);
      expect(updatedGoal.description, '테스트 설명');
    });
  });

  group('MandalartBoard 모델 테스트', () {
    test('MandalartBoard 객체 생성 테스트', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        description: '보드 설명',
        createdAt: now,
      );

      expect(board.id, 1);
      expect(board.centerGoal, '중앙 목표');
      expect(board.description, '보드 설명');
      expect(board.createdAt, now);
      expect(board.subGoals, []);
    });

    test('MandalartBoard toMap 변환 테스트', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        description: '보드 설명',
        createdAt: now,
        updatedAt: now,
      );

      final map = board.toMap();

      expect(map['id'], 1);
      expect(map['center_goal'], '중앙 목표');
      expect(map['description'], '보드 설명');
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('MandalartBoard fromMap 변환 테스트', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'center_goal': '중앙 목표',
        'description': '보드 설명',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final board = MandalartBoard.fromMap(map);

      expect(board.id, 1);
      expect(board.centerGoal, '중앙 목표');
      expect(board.description, '보드 설명');
      expect(board.subGoals, []);
    });

    test('MandalartBoard overallProgress 계산 테스트', () {
      final now = DateTime.now();
      final goals = [
        Goal(
          title: '목표 1',
          parentId: 1,
          position: 0,
          progress: 100,
          createdAt: now,
        ),
        Goal(
          title: '목표 2',
          parentId: 1,
          position: 1,
          progress: 50,
          createdAt: now,
        ),
        Goal(
          title: '목표 3',
          parentId: 1,
          position: 2,
          progress: 0,
          createdAt: now,
        ),
      ];

      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        createdAt: now,
        subGoals: goals,
      );

      // (100 + 50 + 0) / 3 = 50
      expect(board.overallProgress, 50);
    });

    test('MandalartBoard overallProgress 빈 목표 테스트', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        createdAt: now,
        subGoals: [],
      );

      expect(board.overallProgress, 0);
    });

    test('MandalartBoard copyWith 테스트', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        description: '보드 설명',
        createdAt: now,
      );

      final updatedBoard = board.copyWith(
        centerGoal: '수정된 목표',
        description: '수정된 설명',
      );

      expect(updatedBoard.centerGoal, '수정된 목표');
      expect(updatedBoard.description, '수정된 설명');
      expect(updatedBoard.id, 1);
      expect(updatedBoard.createdAt, now);
    });

    test('copyWith는 description을 명시적 null로 지우고, 생략하면 유지한다', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        centerGoal: '중앙 목표',
        description: '보드 설명',
        createdAt: now,
      );
      final goal = Goal(
        title: '목표',
        description: '목표 설명',
        parentId: 1,
        position: 0,
        createdAt: now,
      );

      expect(board.copyWith(description: null).description, isNull);
      expect(board.copyWith(centerGoal: '수정').description, '보드 설명');
      expect(goal.copyWith(description: null).description, isNull);
      expect(goal.copyWith(title: '수정').description, '목표 설명');
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/providers/goal_provider.dart';
import 'package:mandalart/models/goal_model.dart';

void main() {
  group('CurrentBoardNotifier 테스트', () {
    late ProviderContainer container;

    setUp(() async {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 null이어야 함', () {
      final state = container.read(currentBoardProvider);

      expect(state, null);
    });

    test('setBoard로 보드 설정 테스트', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '테스트 목표',
        createdAt: now,
      );

      final notifier = container.read(currentBoardProvider.notifier);
      notifier.setBoard(board);

      final state = container.read(currentBoardProvider);
      expect(state, isNotNull);
      expect(state?.id, 1);
      expect(state?.centerGoal, '테스트 목표');
    });

    test('clearBoard로 보드 초기화 테스트', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '테스트 목표',
        createdAt: now,
      );

      final notifier = container.read(currentBoardProvider.notifier);
      notifier.setBoard(board);

      expect(container.read(currentBoardProvider), isNotNull);

      notifier.clearBoard();

      expect(container.read(currentBoardProvider), null);
    });
  });

  group('Goal 모델 비즈니스 로직 테스트', () {
    test('progress는 0-100 사이 값이어야 함', () {
      final now = DateTime.now();

      final goal1 = Goal(
        title: '목표 1',
        parentId: 1,
        position: 0,
        progress: 0,
        createdAt: now,
      );
      expect(goal1.progress, 0);

      final goal2 = Goal(
        title: '목표 2',
        parentId: 1,
        position: 0,
        progress: 100,
        createdAt: now,
      );
      expect(goal2.progress, 100);

      final goal3 = Goal(
        title: '목표 3',
        parentId: 1,
        position: 0,
        progress: 50,
        createdAt: now,
      );
      expect(goal3.progress, 50);
    });

    test('isCompleted 기본값은 false여야 함', () {
      final now = DateTime.now();
      final goal = Goal(
        title: '목표',
        parentId: 1,
        position: 0,
        createdAt: now,
      );

      expect(goal.isCompleted, false);
    });

    test('Goal position은 0-7 사이여야 함 (8개 세부 목표)', () {
      final now = DateTime.now();

      for (int i = 0; i < 8; i++) {
        final goal = Goal(
          title: '목표 $i',
          parentId: 1,
          position: i,
          createdAt: now,
        );
        expect(goal.position, i);
        expect(goal.position, lessThan(8));
        expect(goal.position, greaterThanOrEqualTo(0));
      }
    });
  });

  group('MandalartBoard 비즈니스 로직 테스트', () {
    test('subGoals가 없으면 overallProgress는 0이어야 함', () {
      final now = DateTime.now();
      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        createdAt: now,
        subGoals: [],
      );

      expect(board.overallProgress, 0);
    });

    test('모든 subGoals의 progress가 100이면 overallProgress는 100이어야 함', () {
      final now = DateTime.now();
      final goals = List.generate(
        8,
        (i) => Goal(
          title: '목표 $i',
          parentId: 1,
          position: i,
          progress: 100,
          createdAt: now,
        ),
      );

      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        createdAt: now,
        subGoals: goals,
      );

      expect(board.overallProgress, 100);
    });

    test('일부 subGoals만 진행되었을 때 평균 계산 테스트', () {
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

      // (100 + 0) / 2 = 50
      expect(board.overallProgress, 50);
    });

    test('8개의 subGoals 모두 다른 progress 값 평균 계산', () {
      final now = DateTime.now();
      final goals = [
        Goal(title: '목표 0', parentId: 1, position: 0, progress: 0, createdAt: now),
        Goal(title: '목표 1', parentId: 1, position: 1, progress: 10, createdAt: now),
        Goal(title: '목표 2', parentId: 1, position: 2, progress: 25, createdAt: now),
        Goal(title: '목표 3', parentId: 1, position: 3, progress: 40, createdAt: now),
        Goal(title: '목표 4', parentId: 1, position: 4, progress: 50, createdAt: now),
        Goal(title: '목표 5', parentId: 1, position: 5, progress: 60, createdAt: now),
        Goal(title: '목표 6', parentId: 1, position: 6, progress: 80, createdAt: now),
        Goal(title: '목표 7', parentId: 1, position: 7, progress: 100, createdAt: now),
      ];

      final board = MandalartBoard(
        id: 1,
        centerGoal: '중앙 목표',
        createdAt: now,
        subGoals: goals,
      );

      // (0 + 10 + 25 + 40 + 50 + 60 + 80 + 100) / 8 = 365 / 8 = 45.625 ≈ 45 (정수 나눗셈)
      expect(board.overallProgress, 45);
    });
  });
}

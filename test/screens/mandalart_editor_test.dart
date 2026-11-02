import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/db/sqlite_helper.dart';
import 'package:mandalart/core/providers/goal_provider.dart';
import 'package:mandalart/models/goal_model.dart';
import 'package:mandalart/screens/mandalart_editor.dart';

class _FakeDb implements SQLiteHelper {
  _FakeDb(this.board) : goals = List.of(board.subGoals);

  final MandalartBoard board;
  final List<Goal> goals;

  MandalartBoard get _current => board.copyWith(subGoals: List.of(goals));

  @override
  Future<MandalartBoard?> readMandalartBoard(int id) async => _current;

  @override
  Future<List<MandalartBoard>> readAllMandalartBoards() async => [_current];

  @override
  Future<int> updateGoal(Goal goal) async {
    goals[goal.position] = goal;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDb db;

  Future<void> openFirstGoalDialog(WidgetTester tester) async {
    // 번역 없이 긴 키 문자열이 그대로 그려져도 넘치지 않도록 화면을 넓힘
    tester.view.physicalSize = const Size(1600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026);
    final board = MandalartBoard(
      id: 1,
      centerGoal: 'Center',
      createdAt: now,
      subGoals: [
        Goal(
          id: 1,
          title: 'Old',
          description: 'Old description',
          parentId: 1,
          position: 0,
          progress: 80,
          createdAt: now,
        ),
      ],
    );
    db = _FakeDb(board);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(currentBoardProvider.notifier).setBoard(board);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MandalartEditor()),
      ),
    );
    await tester.tap(find.text('Old'));
    await tester.pumpAndSettle();
  }

  testWidgets('저장 대기 중 완료를 누르면 마지막 입력이 저장된다', (tester) async {
    await openFirstGoalDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'New');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(db.goals[0].title, 'New');
  });

  testWidgets('제목을 지우면 칸이 비워진다', (tester) async {
    await openFirstGoalDialog(tester);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 600));

    expect(db.goals[0].title, '');
    expect(db.goals[0].description, isNull);
    expect(db.goals[0].progress, 0);
  });
}

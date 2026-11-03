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
    goals[goals.indexWhere((g) => g.id == goal.id)] = goal;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDb db;

  Future<void> openFirstGoalDialog(WidgetTester tester, {int position = 0}) async {
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
          position: position,
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

  testWidgets('제목을 지운 채 닫아도 기존 내용이 유지된다', (tester) async {
    await openFirstGoalDialog(tester);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(db.goals[0].title, 'Old');
    expect(db.goals[0].description, 'Old description');
    expect(db.goals[0].progress, 80);
  });

  testWidgets('칸 비우기를 확인하면 내용이 지워지고, 대기 중 저장이 되살리지 않는다', (tester) async {
    await openFirstGoalDialog(tester);

    await tester.enterText(find.byType(TextField).first, 'Typing');
    await tester.tap(find.text('editor.clear_cell_button'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('editor.clear_cell_button').last);
    await tester.pumpAndSettle();

    expect(db.goals[0].title, '');
    expect(db.goals[0].description, isNull);
    expect(db.goals[0].progress, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('칸 비우기를 취소하면 내용이 유지된다', (tester) async {
    await openFirstGoalDialog(tester);

    await tester.tap(find.text('editor.clear_cell_button'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('home.cancel_button'));
    await tester.pumpAndSettle();

    expect(db.goals[0].title, 'Old');
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();
  });

  testWidgets('칸은 목록 순서가 아니라 position 위치에 표시된다', (tester) async {
    await openFirstGoalDialog(tester, position: 7);
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    final centerTile = find.descendant(
      of: find.byType(GridView),
      matching: find.text('Center'),
    );
    expect(
      tester.getCenter(find.text('Old')).dy,
      greaterThan(tester.getCenter(centerTile).dy),
    );
  });
}

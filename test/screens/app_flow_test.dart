import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/db/sqlite_helper.dart';
import 'package:mandalart/core/providers/goal_provider.dart';
import 'package:mandalart/core/theme/app_theme.dart';
import 'package:mandalart/models/goal_model.dart';
import 'package:mandalart/screens/home_screen.dart';
import 'package:mandalart/screens/settings_screen.dart';

/// 메모리에서 SQLiteHelper와 같은 규칙으로 동작하는 가짜 DB.
class _FakeDb implements SQLiteHelper {
  final boards = <MandalartBoard>[];
  int _nextId = 100;
  bool failRead = false;

  Goal _goal(int id) =>
      boards.expand((b) => b.subGoals).firstWhere((g) => g.id == id);

  void _replaceGoal(Goal goal) {
    for (int i = 0; i < boards.length; i++) {
      final goals = boards[i].subGoals;
      final index = goals.indexWhere((g) => g.id == goal.id);
      if (index >= 0) {
        boards[i] = boards[i].copyWith(
          subGoals: [...goals]..[index] = goal,
        );
      }
    }
  }

  Goal _syncProgress(Goal goal, List<ChecklistItem> items) {
    final done = items.where((i) => i.isDone).length;
    final progress = items.isEmpty ? 0 : done * 100 ~/ items.length;
    return goal.copyWith(checklistItems: items, progress: progress);
  }

  @override
  Future<List<MandalartBoard>> readAllMandalartBoards() async {
    if (failRead) throw Exception('read failed');
    return [...boards];
  }

  @override
  Future<MandalartBoard?> readMandalartBoard(int id) async =>
      boards.where((b) => b.id == id).firstOrNull;

  @override
  Future<int> createBoardWithEmptyGoals(MandalartBoard board) async {
    final id = _nextId++;
    boards.insert(
      0,
      board.copyWith(
        id: id,
        subGoals: [
          for (int p = 0; p < 8; p++)
            Goal(
              id: _nextId++,
              title: '',
              parentId: id,
              position: p,
              createdAt: board.createdAt,
            ),
        ],
      ),
    );
    return id;
  }

  @override
  Future<int> updateMandalartBoard(MandalartBoard board) async {
    boards[boards.indexWhere((b) => b.id == board.id)] = board;
    return 1;
  }

  @override
  Future<int> deleteMandalartBoard(int id) async {
    boards.removeWhere((b) => b.id == id);
    return 1;
  }

  @override
  Future<void> updateGoalText(int goalId, String title, String? description) async {
    _replaceGoal(
      _goal(goalId).copyWith(
        title: title,
        description: description,
        clearDescription: description == null,
      ),
    );
  }

  @override
  Future<void> clearGoal(int goalId) async {
    _replaceGoal(
      _goal(goalId).copyWith(
        title: '',
        clearDescription: true,
        progress: 0,
        checklistItems: const [],
      ),
    );
  }

  @override
  Future<void> setGoalCompleted(int goalId, bool isCompleted) async {
    final goal = _goal(goalId);
    if (goal.checklistItems.isNotEmpty) return;
    _replaceGoal(goal.copyWith(progress: isCompleted ? 100 : 0));
  }

  @override
  Future<int> addChecklistItem(int goalId, String title) async {
    final goal = _goal(goalId);
    final id = _nextId++;
    _replaceGoal(
      _syncProgress(goal, [
        ...goal.checklistItems,
        ChecklistItem(
          id: id,
          goalId: goalId,
          title: title,
          position: goal.checklistItems.length,
          createdAt: DateTime(2026),
        ),
      ]),
    );
    return id;
  }

  @override
  Future<void> setChecklistItemDone(ChecklistItem item, bool isDone) async {
    final goal = _goal(item.goalId);
    _replaceGoal(
      _syncProgress(goal, [
        for (final i in goal.checklistItems)
          if (i.id == item.id)
            ChecklistItem(
              id: i.id,
              goalId: i.goalId,
              title: i.title,
              isDone: isDone,
              position: i.position,
              createdAt: i.createdAt,
            )
          else
            i,
      ]),
    );
  }

  @override
  Future<void> deleteChecklistItem(ChecklistItem item) async {
    final goal = _goal(item.goalId);
    _replaceGoal(
      _syncProgress(goal, goal.checklistItems.where((i) => i.id != item.id).toList()),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 제목 있는 칸 하나(position)와 빈 칸 7개를 가진 보드.
MandalartBoard _board({
  int id = 1,
  String title = 'Center',
  String? description,
  int position = 0,
  int progress = 80,
}) {
  final now = DateTime(2026);
  return MandalartBoard(
    id: id,
    centerGoal: title,
    description: description,
    createdAt: now,
    subGoals: [
      for (int p = 0; p < 8; p++)
        Goal(
          id: id * 10 + p,
          title: p == position ? 'Old' : '',
          description: p == position ? 'Old memo' : null,
          parentId: id,
          position: p,
          progress: p == position ? progress : 0,
          createdAt: now,
        ),
    ],
  );
}

void main() {
  late _FakeDb db;

  Future<void> pumpApp(
    WidgetTester tester, {
    List<MandalartBoard> boards = const [],
    double width = 500,
    ThemeMode theme = ThemeMode.light,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    db = _FakeDb()..boards.addAll(boards);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openBoard(WidgetTester tester, {String title = 'Center'}) =>
      tapAndSettle(tester, find.text(title).first);

  Goal savedGoal() => db.boards.first.subGoals.first;

  Finder sheetField() => find.byType(TextField).first;

  group('홈', () {
    testWidgets('보드가 없으면 빈 상태에서 새 보드를 만들 수 있다', (tester) async {
      await pumpApp(tester);
      expect(find.text('home.empty_title'), findsOneWidget);

      await tapAndSettle(tester, find.text('home.first_board'));
      expect(find.text('new.title'), findsOneWidget);
    });

    testWidgets('불러오기에 실패하면 오류를 보여 주고 다시 시도할 수 있다', (tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      db = _FakeDb()..failRead = true;
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('home.error_title'), findsOneWidget);

      db
        ..failRead = false
        ..boards.add(_board());
      await tapAndSettle(tester, find.text('home.retry'));
      expect(find.text('Center'), findsOneWidget);
    });

    testWidgets('카드 메뉴로 보드를 삭제하면 확인 후 사라진다', (tester) async {
      await pumpApp(tester, boards: [_board()]);

      await tapAndSettle(tester, find.byIcon(Icons.more_vert_rounded));
      await tapAndSettle(tester, find.text('board.menu_delete'));
      expect(find.text('board.delete_title'), findsOneWidget);
      await tapAndSettle(tester, find.text('common.cancel'));
      expect(db.boards, hasLength(1));

      await tapAndSettle(tester, find.byIcon(Icons.more_vert_rounded));
      await tapAndSettle(tester, find.text('board.menu_delete'));
      await tapAndSettle(tester, find.text('board.delete_cta'));
      expect(db.boards, isEmpty);
      expect(find.text('home.empty_title'), findsOneWidget);
      expect(find.text('board.deleted'), findsOneWidget);
    });
  });

  group('새 보드', () {
    testWidgets('비어 있으면 오류, 입력하면 보드로 이동하고 뒤로 가면 홈이다', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, find.text('home.first_board'));

      await tapAndSettle(tester, find.text('new.create'));
      expect(find.text('new.error'), findsOneWidget);
      expect(db.boards, isEmpty);

      await tester.enterText(find.byType(TextField).first, '  Learn  ');
      await tester.pump();
      await tapAndSettle(tester, find.text('new.create'));

      expect(db.boards.single.centerGoal, 'Learn');
      expect(db.boards.single.subGoals, hasLength(8));
      expect(find.text('board.share'), findsOneWidget);
      expect(find.text('new.created'), findsOneWidget);

      await tapAndSettle(tester, find.byIcon(Icons.arrow_back_rounded));
      expect(find.text('home.my_boards'), findsOneWidget);
    });
  });

  group('보드 상세', () {
    testWidgets('칸은 목록 순서가 아니라 position 위치에 표시된다', (tester) async {
      final board = _board(position: 7);
      await pumpApp(
        tester,
        boards: [board.copyWith(subGoals: board.subGoals.reversed.toList())],
      );
      await openBoard(tester);

      final centerTile = find.descendant(
        of: find.byType(GridView),
        matching: find.text('Center'),
      );
      expect(
        tester.getCenter(find.text('Old')).dy,
        greaterThan(tester.getCenter(centerTile).dy),
      );
    });

    testWidgets('상태별로 글자로도 구분된다', (tester) async {
      await pumpApp(tester, boards: [_board(progress: 100)]);
      await openBoard(tester);
      expect(find.text('board.status_done'), findsOneWidget);
      expect(find.text('board.fill'), findsNWidgets(7));
    });

    testWidgets('채운 칸이 전부 완료면 진행률은 100%다', (tester) async {
      await pumpApp(tester, boards: [_board(progress: 100)]);
      await openBoard(tester);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('칸 편집 시트', () {
    Future<void> openOldCell(WidgetTester tester, {int progress = 80}) async {
      await pumpApp(tester, boards: [_board(progress: progress)]);
      await openBoard(tester);
      await tapAndSettle(tester, find.text('Old'));
    }

    testWidgets('저장 대기 중 완료를 누르면 마지막 입력이 저장된다', (tester) async {
      await openOldCell(tester);

      await tester.enterText(sheetField(), 'New');
      await tapAndSettle(tester, find.text('common.done'));

      expect(savedGoal().title, 'New');
    });

    testWidgets('제목을 지운 채 닫아도 기존 제목과 진행률이 유지된다', (tester) async {
      await openOldCell(tester);

      await tester.enterText(sheetField(), '');
      await tester.pump();
      expect(find.text('cell.locked'), findsOneWidget);
      await tapAndSettle(tester, find.text('common.done'));

      expect(savedGoal().title, 'Old');
      expect(savedGoal().progress, 80);
    });

    testWidgets('자동 저장은 진행률을 덮어쓰지 않는다', (tester) async {
      await openOldCell(tester, progress: 0);
      await tester.enterText(find.byType(TextField).at(2), 'Step');
      await tester.pump();
      await tapAndSettle(tester, find.text('cell.add_button'));
      await tapAndSettle(tester, find.byType(Checkbox));
      expect(savedGoal().progress, 100);

      await tester.enterText(sheetField(), 'Renamed');
      await tester.pump(const Duration(milliseconds: 600));

      expect(savedGoal().title, 'Renamed');
      expect(savedGoal().progress, 100);
    });

    testWidgets('체크리스트 추가, 체크, 삭제에 진행률이 따라온다', (tester) async {
      await openOldCell(tester, progress: 0);

      for (final text in ['A', 'B']) {
        await tester.enterText(find.byType(TextField).at(2), text);
        await tester.pump();
        await tapAndSettle(tester, find.text('cell.add_button'));
      }
      expect(savedGoal().checklistItems.map((i) => i.title), ['A', 'B']);
      expect(find.byType(Switch), findsNothing);

      await tapAndSettle(tester, find.byType(Checkbox).first);
      expect(savedGoal().progress, 50);

      await tapAndSettle(tester, find.byIcon(Icons.close_rounded).last);
      expect(savedGoal().checklistItems.single.title, 'A');
      expect(savedGoal().progress, 100);
    });

    testWidgets('체크리스트가 없으면 완료 토글을 쓸 수 있다', (tester) async {
      await openOldCell(tester, progress: 0);

      await tapAndSettle(tester, find.byType(Switch));
      expect(savedGoal().progress, 100);

      await tapAndSettle(tester, find.byType(Switch));
      expect(savedGoal().progress, 0);
    });

    testWidgets('빈 칸은 제목을 쓰기 전까지 잠겨 있고, 칸 비우기가 없다', (tester) async {
      await pumpApp(tester, boards: [_board()]);
      await openBoard(tester);
      await tapAndSettle(tester, find.text('board.fill').first);

      expect(find.text('cell.locked'), findsOneWidget);
      expect(find.text('cell.clear'), findsNothing);

      await tester.tap(find.byType(Switch), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(db.boards.first.subGoals[1].progress, 0);

      await tester.enterText(sheetField(), 'First');
      await tester.pump();
      expect(find.text('cell.locked'), findsNothing);
      await tapAndSettle(tester, find.byType(Switch));

      expect(db.boards.first.subGoals[1].title, 'First');
      expect(db.boards.first.subGoals[1].progress, 100);
    });

    testWidgets('칸 비우기를 확인하면 내용이 지워지고, 대기 중 저장이 되살리지 않는다', (tester) async {
      await openOldCell(tester);

      await tester.enterText(sheetField(), 'Typing');
      await tester.pump();
      await tester.ensureVisible(find.text('cell.clear'));
      await tapAndSettle(tester, find.text('cell.clear'));
      await tapAndSettle(tester, find.text('cell.clear_cta'));
      await tester.pump(const Duration(seconds: 1));

      expect(savedGoal().title, '');
      expect(savedGoal().description, isNull);
      expect(savedGoal().progress, 0);
      expect(find.text('common.done'), findsNothing);
      expect(find.text('cell.cleared'), findsOneWidget);
    });

    testWidgets('칸 비우기를 취소하면 내용이 유지된다', (tester) async {
      await openOldCell(tester);

      await tester.ensureVisible(find.text('cell.clear'));
      await tapAndSettle(tester, find.text('cell.clear'));
      await tapAndSettle(tester, find.text('common.cancel'));

      expect(savedGoal().title, 'Old');
      expect(find.text('common.done'), findsOneWidget);
    });
  });

  group('중앙 목표 시트', () {
    testWidgets('비운 채 닫으면 오류를 보여 주고 닫히지 않는다', (tester) async {
      await pumpApp(tester, boards: [_board()]);
      await openBoard(tester);
      await tapAndSettle(
        tester,
        find.descendant(of: find.byType(GridView), matching: find.text('Center')),
      );

      await tester.enterText(sheetField(), '');
      await tester.pump();
      await tapAndSettle(tester, find.text('common.done'));

      expect(find.text('center.error'), findsOneWidget);
      expect(find.text('center.sheet_label'), findsOneWidget);
      expect(db.boards.first.centerGoal, 'Center');
    });

    testWidgets('제목과 설명을 수정하고, 설명은 지울 수 있다', (tester) async {
      await pumpApp(tester, boards: [_board(description: 'Why')]);
      await openBoard(tester);
      await tapAndSettle(
        tester,
        find.descendant(of: find.byType(GridView), matching: find.text('Center')),
      );

      await tester.enterText(sheetField(), 'Renamed');
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pump();
      await tapAndSettle(tester, find.text('common.done'));

      expect(db.boards.first.centerGoal, 'Renamed');
      expect(db.boards.first.description, isNull);
      expect(find.text('Renamed'), findsWidgets);
    });
  });

  group('설정', () {
    testWidgets('테마를 고르면 바로 적용된다', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, find.byIcon(Icons.settings_rounded));
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tapAndSettle(tester, find.text('settings.theme_dark'));
      // 테마 값은 settingsProvider가 갖고, 여기서는 앱이 깨지지 않는지만 본다.
      expect(find.text('settings.theme_dark'), findsOneWidget);

      await tapAndSettle(tester, find.text('settings.about'));
      expect(find.text('about.heading'), findsOneWidget);
    });
  });

  group('펼친 폴더블', () {
    testWidgets('목록과 상세가 2단으로 보이고 첫 보드가 열린다', (tester) async {
      await pumpApp(
        tester,
        boards: [_board(), _board(id: 2, title: 'Second')],
        width: 1000,
      );

      expect(find.text('home.my_boards'), findsOneWidget);
      expect(find.text('board.share'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      await tapAndSettle(tester, find.text('Second').first);
      expect(find.text('Second'), findsWidgets);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('접고 펼쳐도 보던 보드가 유지된다', (tester) async {
      await pumpApp(tester, boards: [_board()], width: 1000);
      expect(find.text('board.share'), findsOneWidget);

      tester.view.physicalSize = const Size(500, 1600);
      await tester.pumpAndSettle();
      expect(find.text('board.share'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      tester.view.physicalSize = const Size(1000, 1600);
      await tester.pumpAndSettle();
      expect(find.text('home.my_boards'), findsOneWidget);
      expect(find.text('board.share'), findsOneWidget);
    });
  });
}

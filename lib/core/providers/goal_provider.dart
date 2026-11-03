import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/goal_model.dart';
import '../db/sqlite_helper.dart';

final databaseProvider = Provider<SQLiteHelper>((ref) {
  return SQLiteHelper.instance;
});

class MandalartBoardsNotifier extends StateNotifier<AsyncValue<List<MandalartBoard>>> {
  final SQLiteHelper _db;

  MandalartBoardsNotifier(this._db) : super(const AsyncValue.loading()) {
    loadBoards();
  }

  // 초기 상태만 loading. 갱신 중에는 기존 목록을 유지해 스크롤 위치가 초기화되지 않음
  Future<void> loadBoards() async {
    try {
      final boards = await _db.readAllMandalartBoards();
      state = AsyncValue.data(boards);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createBoard(MandalartBoard board) async {
    try {
      await _db.createMandalartBoard(board);
      await loadBoards();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBoard(MandalartBoard board) async {
    try {
      await _db.updateMandalartBoard(board);
      await loadBoards();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBoard(int id) async {
    try {
      await _db.deleteMandalartBoard(id);
      await loadBoards();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final mandalartBoardsProvider =
    StateNotifierProvider<MandalartBoardsNotifier, AsyncValue<List<MandalartBoard>>>((ref) {
  final db = ref.watch(databaseProvider);
  return MandalartBoardsNotifier(db);
});

class CurrentBoardNotifier extends StateNotifier<MandalartBoard?> {
  final SQLiteHelper _db;
  final Ref _ref;

  CurrentBoardNotifier(this._db, this._ref) : super(null);

  Future<void> loadBoard(int id) async {
    final board = await _db.readMandalartBoard(id);
    state = board;
  }

  void setBoard(MandalartBoard board) {
    state = board;
  }

  void clearBoard() {
    state = null;
  }

  Future<void> updateGoalText(int goalId, String title, String? description) =>
      _writeAndRefresh(() => _db.updateGoalText(goalId, title, description));

  Future<void> updateBoardText(String centerGoal, String? description) {
    final board = state;
    if (board == null) return Future.value();
    return _writeAndRefresh(
      () => _db.updateMandalartBoard(
        board.copyWith(
          centerGoal: centerGoal,
          description: description,
          clearDescription: description == null,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> clearGoal(int goalId) =>
      _writeAndRefresh(() => _db.clearGoal(goalId));

  Future<void> setGoalCompleted(int goalId, bool isCompleted) =>
      _writeAndRefresh(() => _db.setGoalCompleted(goalId, isCompleted));

  Future<void> addChecklistItem(int goalId, String title) =>
      _writeAndRefresh(() => _db.addChecklistItem(goalId, title));

  Future<void> setChecklistItemDone(ChecklistItem item, bool isDone) =>
      _writeAndRefresh(() => _db.setChecklistItemDone(item, isDone));

  Future<void> deleteChecklistItem(ChecklistItem item) =>
      _writeAndRefresh(() => _db.deleteChecklistItem(item));

  /// 저장 후 현재 보드와 홈 목록을 함께 갱신한다. 저장 실패는 호출한 쪽으로 전달한다.
  Future<void> _writeAndRefresh(Future<void> Function() write) async {
    final boardId = state?.id;
    if (boardId == null) return;

    await write();
    state = await _db.readMandalartBoard(boardId);
    await _ref.read(mandalartBoardsProvider.notifier).loadBoards();
  }
}

final currentBoardProvider = StateNotifierProvider<CurrentBoardNotifier, MandalartBoard?>((ref) {
  final db = ref.watch(databaseProvider);
  return CurrentBoardNotifier(db, ref);
});

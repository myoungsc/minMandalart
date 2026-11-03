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

  Future<void> updateGoal(Goal goal) async {
    if (state == null) return;

    try {
      await _db.updateGoal(goal);
      final updatedBoard = await _db.readMandalartBoard(state!.id!);
      state = updatedBoard;

      // 메인 화면의 보드 목록도 업데이트
      _ref.read(mandalartBoardsProvider.notifier).loadBoards();
    } catch (e) {
      rethrow;
    }
  }
}

final currentBoardProvider = StateNotifierProvider<CurrentBoardNotifier, MandalartBoard?>((ref) {
  final db = ref.watch(databaseProvider);
  return CurrentBoardNotifier(db, ref);
});

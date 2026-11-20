import 'dart:convert';

import '../../models/goal_model.dart';

const _app = 'miniManda';
const _format = 1;
// 앱 입력칸의 maxLength와 같다(new_board_screen, cell_sheets).
const _maxTitleLength = 40;
const _maxDescriptionLength = 100;

/// 손으로 고친 파일이 앱에서 만들 수 없는 길이의 값을 넣지 못하게 막는다.
void _checkLength(String title, String? description) {
  if (title.length > _maxTitleLength ||
      (description?.length ?? 0) > _maxDescriptionLength) {
    throw const FormatException('글자 수 제한 초과');
  }
}

/// 보드 목록(체크리스트 포함)을 백업 JSON 문자열로 만든다.
String encodeBackup(List<MandalartBoard> boards, {DateTime? now}) {
  return const JsonEncoder.withIndent('  ').convert({
    'app': _app,
    'format': _format,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'boards': [
      for (final board in boards)
        {
          ...board.toMap(),
          'goals': [
            for (final goal in board.subGoals)
              {
                ...goal.toMap(),
                'checklist': [for (final item in goal.checklistItems) item.toMap()],
              },
          ],
        },
    ],
  });
}

/// 백업 JSON을 읽는다. 형식이 맞지 않으면 [FormatException].
/// id는 믿지 않으므로 DB에 넣을 때 새로 발급해야 한다.
List<MandalartBoard> decodeBackup(String json) {
  try {
    final root = jsonDecode(json) as Map<String, dynamic>;
    if (root['app'] != _app) throw const FormatException('app이 다름');
    if (root['format'] != _format) throw const FormatException('지원하지 않는 format');
    final boards = root['boards'] as List;
    // 빈 파일로 교체하면 기존 보드만 지워지므로 막는다.
    if (boards.isEmpty) throw const FormatException('보드가 없음');
    return [for (final b in boards) _decodeBoard(b as Map<String, dynamic>)];
  } on FormatException {
    rethrow;
  } on TypeError catch (e) {
    // fromMap의 `as` 형변환 실패: 타입이 틀리거나 키가 없는 파일
    throw FormatException('잘못된 값: $e');
  }
}

MandalartBoard _decodeBoard(Map<String, dynamic> map) {
  final centerGoal = map['center_goal'] as String;
  if (centerGoal.trim().isEmpty) throw const FormatException('핵심 목표가 비어 있음');
  final board = MandalartBoard.fromMap(map);
  _checkLength(board.centerGoal, board.description);

  final goals = <int, Goal>{};
  for (final g in map['goals'] as List) {
    final goal = _decodeGoal(g as Map<String, dynamic>);
    if (goal.position < 0 || goal.position > 7) {
      throw const FormatException('칸 위치가 0~7을 벗어남');
    }
    if (goals.containsKey(goal.position)) throw const FormatException('칸 위치 중복');
    goals[goal.position] = goal;
  }

  return board.copyWith(
    subGoals: [
      for (int position = 0; position < 8; position++)
        goals[position] ??
            Goal(
              title: '',
              parentId: board.id ?? 0,
              position: position,
              createdAt: board.createdAt,
            ),
    ],
  );
}

Goal _decodeGoal(Map<String, dynamic> map) {
  final goal = Goal.fromMap(
    map,
    checklistItems: [
      for (final c in map['checklist'] as List? ?? const [])
        ChecklistItem.fromMap(c as Map<String, dynamic>),
    ],
  );
  _checkLength(goal.title, goal.description);
  // 빈 칸은 앱의 clearGoal과 같은 상태로 맞춘다.
  if (goal.title.isEmpty) {
    return goal.copyWith(
      progress: 0,
      clearDescription: true,
      checklistItems: const [],
    );
  }
  return goal.copyWith(progress: goal.progress.clamp(0, 100));
}

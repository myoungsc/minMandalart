import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/backup/backup_codec.dart';
import 'package:mandalart/models/goal_model.dart';

MandalartBoard _board() {
  final now = DateTime(2026, 1, 2, 3, 4, 5);
  return MandalartBoard(
    id: 7,
    centerGoal: '영어 회화',
    description: '올해 목표',
    createdAt: now,
    updatedAt: now,
    subGoals: [
      for (int p = 0; p < 8; p++)
        Goal(
          id: 70 + p,
          title: p == 0 ? '단어' : (p == 1 ? '듣기' : ''),
          description: p == 0 ? '매일 10개' : null,
          parentId: 7,
          position: p,
          progress: p == 0 ? 50 : (p == 1 ? 100 : 0),
          createdAt: now,
          checklistItems: p == 0
              ? [
                  ChecklistItem(id: 1, goalId: 70, title: '1주차', isDone: true, position: 0, createdAt: now),
                  ChecklistItem(id: 2, goalId: 70, title: '2주차', position: 1, createdAt: now),
                ]
              : const [],
        ),
    ],
  );
}

/// 정상 백업을 Map으로 받아 고친 뒤 다시 JSON으로 만든다.
String _edited(void Function(Map<String, dynamic> root) edit) {
  final root = jsonDecode(encodeBackup([_board()])) as Map<String, dynamic>;
  edit(root);
  return jsonEncode(root);
}

List<dynamic> _goals(Map<String, dynamic> root) =>
    (root['boards'] as List).first['goals'] as List;

void main() {
  test('왕복 후 제목·메모·진행률·체크리스트가 같다', () {
    final board = decodeBackup(encodeBackup([_board()], now: DateTime(2026))).single;

    expect(board.centerGoal, '영어 회화');
    expect(board.description, '올해 목표');
    expect(board.subGoals, hasLength(8));
    final first = board.subGoals[0];
    expect(first.title, '단어');
    expect(first.description, '매일 10개');
    expect(first.progress, 50);
    expect(first.checklistItems.map((i) => (i.title, i.isDone, i.position)), [
      ('1주차', true, 0),
      ('2주차', false, 1),
    ]);
    expect(board.subGoals[1].progress, 100);
  });

  test('머리 정보를 담는다', () {
    final root = jsonDecode(encodeBackup([_board()], now: DateTime(2026))) as Map;
    expect(root['app'], 'miniManda');
    expect(root['format'], 1);
    expect(root['exportedAt'], DateTime(2026).toIso8601String());
  });

  group('형식이 틀리면 FormatException', () {
    final cases = <String, String>{
      'app이 다름': _edited((r) => r['app'] = 'other'),
      'format 2': _edited((r) => r['format'] = 2),
      '빈 boards': _edited((r) => r['boards'] = []),
      '핵심 목표가 빈 문자열': _edited((r) => (r['boards'] as List).first['center_goal'] = ' '),
      'position 중복': _edited((r) => _goals(r)[1]['position'] = 0),
      'position 범위 밖': _edited((r) => _goals(r)[1]['position'] = 8),
      '제목이 숫자': _edited((r) => _goals(r)[0]['title'] = 3),
      'goals 없음': _edited((r) => (r['boards'] as List).first.remove('goals')),
      '최상위가 리스트': '[]',
      '깨진 JSON': '{"app":',
      '핵심 목표 41자': _edited((r) => (r['boards'] as List).first['center_goal'] = 'a' * 41),
      '칸 제목 41자': _edited((r) => _goals(r)[0]['title'] = 'a' * 41),
      '칸 메모 101자': _edited((r) => _goals(r)[0]['description'] = 'a' * 101),
    };
    cases.forEach((name, json) {
      test(name, () => expect(() => decodeBackup(json), throwsFormatException));
    });
  });

  test('goals가 5개면 빠진 칸을 빈 칸으로 채워 8개가 된다', () {
    final json = _edited((r) => _goals(r).removeRange(3, 6));
    final board = decodeBackup(json).single;

    expect(board.subGoals.map((g) => g.position), [0, 1, 2, 3, 4, 5, 6, 7]);
    expect(board.subGoals[4].title, '');
    expect(board.subGoals[4].createdAt, board.createdAt);
  });

  test('제목이 빈 칸의 체크리스트·진행률·메모는 버린다', () {
    final json = _edited((r) {
      _goals(r)[0]['title'] = '';
      _goals(r)[0]['progress'] = 50;
    });
    final goal = decodeBackup(json).single.subGoals[0];

    expect(goal.checklistItems, isEmpty);
    expect(goal.progress, 0);
    expect(goal.description, isNull);
  });

  test('진행률은 0~100으로 제한한다', () {
    final json = _edited((r) => _goals(r)[1]['progress'] = 250);
    expect(decodeBackup(json).single.subGoals[1].progress, 100);
  });
}

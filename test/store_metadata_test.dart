import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 스토어 글자 수 제한. 키워드만 바이트로 센다.
const _ios = {
  'name.txt': 30,
  'subtitle.txt': 30,
  'promotional_text.txt': 170,
  'description.txt': 4000,
  'release_notes.txt': 4000,
};
const _android = {
  'title.txt': 30,
  'short_description.txt': 80,
  'full_description.txt': 4000,
  'changelogs/default.txt': 500,
};

String _read(String path) => File(path).readAsStringSync().trim();

// review_information 은 언어 폴더가 아니다(심사 메모).
List<Directory> _langDirs(String root) => Directory(root)
    .listSync()
    .whereType<Directory>()
    .where((d) => !d.path.endsWith('review_information'))
    .toList();

void _checkLimits(String root, Map<String, int> limits, int languages) {
  final dirs = _langDirs(root);
  expect(dirs, hasLength(languages));
  for (final dir in dirs) {
    for (final e in limits.entries) {
      final text = _read('${dir.path}/${e.key}');
      expect(text, isNotEmpty, reason: '${dir.path}/${e.key}');
      expect(text.runes.length, lessThanOrEqualTo(e.value), reason: '${dir.path}/${e.key}');
    }
  }
}

void main() {
  test('App Store 소개 문구가 제한 안에 있다', () {
    _checkLimits('fastlane/metadata/ios', _ios, 6);
    for (final dir in _langDirs('fastlane/metadata/ios')) {
      final bytes = utf8.encode(_read('${dir.path}/keywords.txt')).length;
      expect(bytes, lessThanOrEqualTo(100), reason: dir.path);
    }
    final notes = _read('fastlane/metadata/ios/review_information/notes.txt');
    expect(notes.runes.length, lessThanOrEqualTo(4000));
  });

  test('Play 소개 문구가 제한 안에 있다', () {
    _checkLimits('fastlane/metadata/android', _android, 6);
  });
}

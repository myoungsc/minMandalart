import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, String> _flatten(Map<String, dynamic> map, [String prefix = '']) => {
  for (final e in map.entries)
    if (e.value is Map<String, dynamic>)
      ..._flatten(e.value as Map<String, dynamic>, '$prefix${e.key}.')
    else
      '$prefix${e.key}': e.value as String,
};

Map<String, String> _load(String language) => _flatten(
  jsonDecode(File('assets/translations/$language.json').readAsStringSync())
      as Map<String, dynamic>,
);

Set<String> _args(String text) =>
    RegExp(r'\{\w+\}').allMatches(text).map((m) => m.group(0)!).toSet();

void main() {
  final en = _load('en');

  for (final language in ['ko', 'ja', 'es', 'ru', 'fr']) {
    test('$language 번역은 키와 변수가 영어와 같다', () {
      final other = _load(language);
      expect(other.keys.toSet(), en.keys.toSet());
      for (final key in en.keys) {
        expect(other[key]!.trim(), isNotEmpty, reason: key);
        expect(_args(other[key]!), _args(en[key]!), reason: key);
      }
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/notifications/reminder_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location seoul;
  late tz.Location newYork;

  setUpAll(() {
    tz_data.initializeTimeZones();
    seoul = tz.getLocation('Asia/Seoul');
    newYork = tz.getLocation('America/New_York');
  });

  const nine = TimeOfDay(hour: 21, minute: 0);

  group('nextReminderTime', () {
    test('오늘 그 시각 전이면 오늘', () {
      final now = tz.TZDateTime(seoul, 2026, 11, 19, 20, 59);
      expect(
        nextReminderTime(nine, now),
        tz.TZDateTime(seoul, 2026, 11, 19, 21),
      );
    });

    test('정확히 그 시각이거나 지났으면 내일', () {
      final at = tz.TZDateTime(seoul, 2026, 11, 19, 21);
      expect(
        nextReminderTime(nine, at),
        tz.TZDateTime(seoul, 2026, 11, 20, 21),
      );
      final after = tz.TZDateTime(seoul, 2026, 11, 19, 23, 30);
      expect(
        nextReminderTime(nine, after),
        tz.TZDateTime(seoul, 2026, 11, 20, 21),
      );
    });

    test('달과 해가 넘어가도 다음 날로 맞춘다', () {
      final now = tz.TZDateTime(seoul, 2026, 12, 31, 22);
      expect(nextReminderTime(nine, now), tz.TZDateTime(seoul, 2027, 1, 1, 21));
    });

    test('기기 시간대의 벽시계 시각으로 예약한다 (UTC가 아니다)', () {
      final now = tz.TZDateTime(seoul, 2026, 11, 19, 8);
      final next = nextReminderTime(nine, now);
      expect(next.hour, 21);
      expect(next.toUtc().hour, 12); // 서울은 UTC+9
    });

    test('서머타임이 바뀌는 날에도 벽시계 시각을 지킨다', () {
      // 2026-03-08 미국 동부 서머타임 시작 (UTC-5 → UTC-4)
      final now = tz.TZDateTime(newYork, 2026, 3, 7, 22);
      final next = nextReminderTime(nine, now);
      expect(next, tz.TZDateTime(newYork, 2026, 3, 8, 21));
      expect(next.toUtc().hour, 1); // 21시 + 4시간
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/notifications/reminder_service.dart';
import 'package:mandalart/core/providers/settings_provider.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 플랫폼 채널 없이 호출만 기록하는 플러그인.
class _FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  int initFailures = 0;
  int initCalls = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initCalls++;
    if (initFailures > 0) {
      initFailures--;
      throw Exception('init 실패');
    }
    return true;
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduleCalls++;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async => cancelCalls++;
}

/// 컨트롤러 테스트용 서비스. 실패와 권한을 조절한다.
class _FakeService implements ReminderService {
  bool permission = true;
  bool failSchedule = false;
  final calls = <String>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    calls.add('request');
    return permission;
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> schedule(
    TimeOfDay time, {
    required String title,
    required String body,
    required String channelName,
  }) async {
    calls.add('schedule');
    if (failSchedule) throw Exception('예약 실패');
  }

  @override
  Future<void> cancel() async => calls.add('cancel');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('시간대 이름을 못 읽었을 때 대체 지역', () {
    Duration offset(tz.Location l, int month) =>
        tz.TZDateTime.from(DateTime.utc(2026, month, 1), l).timeZoneOffset;

    for (final name in [
      'America/New_York',
      'Europe/London',
      'Asia/Seoul',
      'Australia/Sydney',
    ]) {
      test('$name과 1월·7월 UTC 차이가 모두 같은 지역을 고른다', () {
        final real = tz.getLocation(name);
        final picked = ReminderService.locationForOffsets(
          winter: offset(real, 1),
          summer: offset(real, 7),
          year: 2026,
        );
        expect(offset(picked, 1), offset(real, 1));
        expect(offset(picked, 7), offset(real, 7));
      });
    }
  });

  group('ReminderService', () {
    test('초기화가 실패하면 다음 호출에서 다시 시도한다', () async {
      final plugin = _FakePlugin()..initFailures = 1;
      final service = ReminderService(plugin);

      await expectLater(service.cancel(), throwsException);
      await service.cancel();
      expect(plugin.initCalls, 2);
      expect(plugin.cancelCalls, 1);

      // 성공한 뒤에는 다시 초기화하지 않는다.
      await service.cancel();
      expect(plugin.initCalls, 2);
    });

    test('같은 내용이면 다시 예약하지 않고, 취소한 뒤에는 다시 예약한다', () async {
      final plugin = _FakePlugin();
      final service = ReminderService(plugin);
      Future<void> schedule(String title) =>
          service.schedule(nine, title: title, body: 'b', channelName: 'c');

      await schedule('a');
      await schedule('a');
      expect(plugin.scheduleCalls, 1);

      await schedule('언어가 바뀐 문구');
      expect(plugin.scheduleCalls, 2);

      await service.cancel();
      await schedule('언어가 바뀐 문구');
      expect(plugin.scheduleCalls, 3);
    });
  });

  group('ReminderController', () {
    late _FakeService service;
    late ProviderContainer container;

    setUp(() {
      service = _FakeService();
      container = ProviderContainer(
        overrides: [reminderServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
    });

    ReminderController controller() =>
        container.read(reminderControllerProvider.notifier);
    bool enabled() => container.read(settingsProvider).reminderEnabled;

    test('예약에 실패하면 설정을 끄고 걸려 있던 알림도 취소한다', () async {
      await controller().setEnabled(true);
      expect(enabled(), isTrue);

      service.failSchedule = true;
      await expectLater(
        controller().setTime(const TimeOfDay(hour: 7, minute: 30)),
        throwsException,
      );
      expect(enabled(), isFalse);
      expect(service.calls.last, 'cancel');
    });

    test('처리 중에 다시 요청하면 무시한다', () async {
      final first = controller().setEnabled(true);
      expect(await controller().setEnabled(true), ReminderOutcome.busy);
      expect(await first, ReminderOutcome.done);
      expect(service.calls.where((c) => c == 'request'), hasLength(1));
    });

    test('기기 설정에서 권한을 끈 뒤 돌아오면 설정도 끄고 예약을 지운다', () async {
      await controller().setEnabled(true);
      service.permission = false;

      expect(await controller().resync(), ReminderOutcome.denied);
      expect(enabled(), isFalse);
      expect(service.calls.last, 'cancel');
    });

    test('다시 예약이 일시적으로 실패해도 사용자가 켠 설정은 유지한다', () async {
      await controller().setEnabled(true);
      service.failSchedule = true;

      await expectLater(controller().resync(), throwsException);
      expect(enabled(), isTrue);
      expect(service.calls.last, 'schedule');
    });

    test('꺼져 있으면 다시 예약하지 않는다', () async {
      expect(await controller().resync(), ReminderOutcome.done);
      expect(service.calls, isEmpty);
    });
  });
}

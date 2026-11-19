import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../providers/settings_provider.dart';

/// 하루 한 번 "오늘 목표 확인" 로컬 알림을 예약하고 취소한다.
class ReminderService {
  ReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// 알림은 하나뿐이라 id를 고정한다. 다시 예약하면 같은 id로 덮어쓴다.
  static const _id = 1;

  Future<void>? _ready;

  /// 여러 번 불러도 한 번만 초기화한다. 권한은 요청하지 않는다.
  Future<void> init() => _ready ??= _init();

  Future<void> _init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(await _deviceLocation());
    await _plugin.initialize(
      settings: const InitializationSettings(
        // 런처 아이콘의 단색 버전(투명 배경, 흰 격자)을 상태바 아이콘으로 쓴다.
        // 적응형 아이콘이 참조하는 리소스라 릴리스 빌드에서 지워지지 않는다.
        android: AndroidInitializationSettings('ic_launcher_monochrome'),
        // 기본값이 true라 그대로 두면 첫 실행 때 권한 팝업이 뜬다.
        // 권한은 설정에서 스위치를 켤 때 requestPermission()으로만 요청한다.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
  }

  /// timezone 패키지의 기본 지역은 UTC라서 기기 시간대를 직접 넣어야 한다.
  static Future<tz.Location> _deviceLocation() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return tz.getLocation(info.identifier);
    } catch (e) {
      // 시간대 이름을 못 얻었거나 DB에 없는 이름이면 현재 UTC 차이가 같은 지역으로 대신한다.
      debugPrint('기기 시간대를 읽지 못함: $e');
      final offset = DateTime.now().timeZoneOffset;
      return tz.timeZoneDatabase.locations.values.firstWhere(
        (l) => l.currentTimeZone.offset == offset,
        orElse: () => tz.UTC,
      );
    }
  }

  /// 알림 권한을 요청한다. 이미 허용돼 있으면 팝업 없이 true.
  Future<bool> requestPermission() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// 매일 [time]에 울리도록 예약한다. 문구는 예약하는 시점의 언어로 저장된다.
  Future<void> schedule(
    TimeOfDay time, {
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.zonedSchedule(
      id: _id,
      scheduledDate: nextReminderTime(time, tz.TZDateTime.now(tz.local)),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          // 채널 이름은 기기 알림 설정에 보인다.
          title,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // 정확 알람 권한(Play 정책 설명 필요)을 피하려고 비정확 알람만 쓴다. 몇 분 늦을 수 있다.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(id: _id);
  }
}

/// [now] 이후 처음 오는 [time]. 오늘 그 시각이 지났거나 지금이면 내일.
tz.TZDateTime nextReminderTime(TimeOfDay time, tz.TZDateTime now) {
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      time.hour,
      time.minute,
    );
  }
  return next;
}

/// 설정 값에 맞춰 예약하거나 취소한다. 문구는 지금 언어로 만든다.
Future<void> syncReminder(ReminderService service, AppSettings settings) {
  if (!settings.reminderEnabled) return service.cancel();
  return service.schedule(
    settings.reminderTime,
    title: 'reminder.title'.tr(),
    body: 'reminder.body'.tr(),
  );
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(FlutterLocalNotificationsPlugin()),
);

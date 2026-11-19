import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
// 앞으로 10년 규칙만 담은 작은 DB. 매일 알림에는 충분하고 전체 DB보다 훨씬 빨리 읽힌다.
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../providers/settings_provider.dart';

/// 알림 기능은 휴대폰(Android, iOS)에서만 제공한다.
bool get reminderSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// 하루 한 번 "오늘 목표 확인" 로컬 알림을 예약하고 취소한다.
class ReminderService {
  ReminderService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// 알림은 하나뿐이라 id를 고정한다. 다시 예약하면 같은 id로 덮어쓴다.
  static const _id = 1;

  Future<void>? _ready;

  /// 마지막으로 예약한 내용. 같으면 다시 예약하지 않는다.
  String? _scheduledKey;

  /// 여러 번 불러도 한 번만 초기화한다. 권한은 요청하지 않는다.
  /// 실패하면 다음 호출에서 다시 시도한다.
  Future<void> init() =>
      _ready ??= _init().catchError((Object e, StackTrace s) {
        _ready = null;
        Error.throwWithStackTrace(e, s);
      });

  Future<void> _init() async {
    tz_data.initializeTimeZones();
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
  /// 여행 중에 바뀔 수 있으므로 예약할 때마다 다시 읽는다.
  static Future<void> _applyDeviceTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('기기 시간대를 읽지 못함: $e');
      final year = DateTime.now().year;
      tz.setLocalLocation(
        locationForOffsets(
          winter: DateTime(year, 1, 1).timeZoneOffset,
          summer: DateTime(year, 7, 1).timeZoneOffset,
          year: year,
        ),
      );
    }
  }

  /// 시간대 이름을 못 얻었을 때 쓰는 대체 지역.
  /// 1월과 7월의 UTC 차이가 모두 같은 지역을 골라 서머타임 규칙까지 맞춘다.
  @visibleForTesting
  static tz.Location locationForOffsets({
    required Duration winter,
    required Duration summer,
    required int year,
  }) {
    Duration offsetAt(tz.Location l, int month) =>
        tz.TZDateTime.from(DateTime.utc(year, month, 1), l).timeZoneOffset;
    return tz.timeZoneDatabase.locations.values.firstWhere(
      (l) => offsetAt(l, 1) == winter && offsetAt(l, 7) == summer,
      orElse: () => tz.UTC,
    );
  }

  /// 알림 권한을 요청한다. 이미 허용돼 있으면 팝업 없이 true.
  Future<bool> requestPermission() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return false;
  }

  /// 팝업 없이 지금 알림이 허용돼 있는지 확인한다. 기기 설정에서 끈 경우를 잡는다.
  Future<bool> hasPermission() async {
    await init();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (await _ios?.checkPermissions())?.isEnabled ?? false;
    }
    return false;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// 매일 [time]에 울리도록 예약한다. 문구는 예약하는 시점의 언어로 저장된다.
  /// [channelName]은 기기 알림 설정에 보이는 분류 이름이다.
  Future<void> schedule(
    TimeOfDay time, {
    required String title,
    required String body,
    required String channelName,
  }) async {
    await init();
    await _applyDeviceTimeZone();
    final key = [
      tz.local.name,
      time.hour,
      time.minute,
      title,
      body,
      channelName,
    ].join('|');
    if (key == _scheduledKey) return;
    await _plugin.zonedSchedule(
      id: _id,
      scheduledDate: nextReminderTime(time, tz.TZDateTime.now(tz.local)),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('daily_reminder', channelName),
        iOS: const DarwinNotificationDetails(),
      ),
      // 정확 알람 권한(Play 정책 설명 필요)을 피하려고 비정확 알람만 쓴다. 몇 분 늦을 수 있다.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    _scheduledKey = key;
  }

  Future<void> cancel() async {
    await init();
    _scheduledKey = null;
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

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(FlutterLocalNotificationsPlugin()),
);

enum ReminderOutcome { done, denied, busy }

/// 알림 설정 변경과 예약을 한곳에서 처리한다. 상태 값은 처리 중 여부다.
class ReminderController extends StateNotifier<bool> {
  ReminderController(this._ref) : super(false);

  final Ref _ref;

  ReminderService get _service => _ref.read(reminderServiceProvider);
  SettingsNotifier get _settings => _ref.read(settingsProvider.notifier);

  /// 켤 때만 권한을 묻는다. 거부되면 꺼진 채로 둔다.
  Future<ReminderOutcome> setEnabled(bool on) => _run(() async {
    if (on && !await _service.requestPermission()) {
      return ReminderOutcome.denied;
    }
    _settings.setReminderEnabled(on);
    await _apply();
    return ReminderOutcome.done;
  });

  Future<ReminderOutcome> setTime(TimeOfDay time) => _run(() async {
    _settings.setReminderTime(time);
    await _apply();
    return ReminderOutcome.done;
  });

  /// 앱을 켤 때, 앱으로 돌아올 때, 언어가 바뀔 때 부른다.
  /// 지금 언어와 시간대로 다시 예약하고, 기기 설정에서 권한을 껐으면 설정도 끈다.
  Future<ReminderOutcome> resync() async {
    if (!reminderSupported || !_ref.read(settingsProvider).reminderEnabled) {
      return ReminderOutcome.done;
    }
    // 일시적인 실패로 사용자가 켠 설정을 끄지 않는다. 기존 예약은 그대로 남는다.
    return _run(rollbackOnError: false, () async {
      if (!await _service.hasPermission()) {
        _settings.setReminderEnabled(false);
        await _service.cancel();
        return ReminderOutcome.denied;
      }
      await _apply();
      return ReminderOutcome.done;
    });
  }

  Future<void> _apply() {
    final s = _ref.read(settingsProvider);
    if (!s.reminderEnabled) return _service.cancel();
    return _service.schedule(
      s.reminderTime,
      title: 'reminder.title'.tr(),
      body: 'reminder.body'.tr(),
      channelName: 'settings.reminder_enabled'.tr(),
    );
  }

  /// 한 번에 하나만 처리한다(권한 팝업 중 다시 누르기, 앱 복귀와 겹치기).
  Future<ReminderOutcome> _run(
    Future<ReminderOutcome> Function() body, {
    bool rollbackOnError = true,
  }) async {
    if (state) return ReminderOutcome.busy;
    state = true;
    try {
      return await body();
    } catch (_) {
      if (rollbackOnError) {
        // 켜진 것처럼 보이지 않게 끄고, 남아 있을 수 있는 예전 알림도 지운다.
        _settings.setReminderEnabled(false);
        try {
          await _service.cancel();
        } catch (e) {
          debugPrint('알림 취소 실패: $e');
        }
      }
      rethrow;
    } finally {
      if (mounted) state = false;
    }
  }
}

final reminderControllerProvider =
    StateNotifierProvider<ReminderController, bool>(ReminderController.new);

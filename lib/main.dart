import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/notifications/reminder_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/today_provider.dart';
import 'core/widgets/mm_widgets.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // 첫 화면부터 저장된 테마로 그리기 위해 미리 읽는다.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('es'),
        Locale('ru'),
        Locale('fr'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 테마만 본다. 알림 설정이 바뀔 때 앱 전체를 다시 그리지 않는다.
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp(
      onGenerateTitle: (context) => 'app.name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // dismissKeyboardOnTap은 그대로 두고, 날짜가 바뀌면 남은 일수가 갱신되게 감싼다.
      builder: (context, child) => TodayRefresher(
        child: _ReminderResync(child: dismissKeyboardOnTap(context, child)),
      ),
      home: const HomeScreen(),
    );
  }
}

/// 알림 문구는 예약한 시점의 언어로, 시각은 그때의 시간대로 저장된다.
/// 앱을 켤 때, 기기 언어가 바뀔 때, 앱으로 돌아올 때(여행으로 시간대가 바뀌었거나
/// 기기 설정에서 권한을 껐을 수 있다) 지금 상태에 맞게 다시 예약한다.
/// MyApp(Localizations 바깥)의 첫 프레임은 번역 로드 전이라 키 문자열이 그대로 들어간다.
/// 그래서 번역이 로드된 뒤에야 그려지는 MaterialApp.builder 안쪽에 둔다.
class _ReminderResync extends ConsumerStatefulWidget {
  final Widget child;

  const _ReminderResync({required this.child});

  @override
  ConsumerState<_ReminderResync> createState() => _ReminderResyncState();
}

class _ReminderResyncState extends ConsumerState<_ReminderResync> {
  late final AppLifecycleListener _lifecycle;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _resync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 처음 그릴 때와 언어가 바뀔 때. Localizations는 번역 로드가 끝난 뒤에 locale을 바꾼다.
    final locale = Localizations.localeOf(context);
    if (locale == _locale) return;
    _locale = locale;
    // 첫 프레임을 막지 않게 그린 뒤에 시작하고 기다리지 않는다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resync());
  }

  void _resync() {
    if (!mounted) return;
    ref.read(reminderControllerProvider.notifier).resync().catchError((Object e) {
      debugPrint('알림 다시 예약 실패: $e');
      return ReminderOutcome.done;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/notifications/reminder_service.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
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
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      onGenerateTitle: (context) => 'app.name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) =>
          _ReminderResync(child: dismissKeyboardOnTap(context, child)),
      home: const HomeScreen(),
    );
  }
}

/// 알림 문구는 예약한 시점의 언어로 저장된다. 앱을 켤 때 알림이 켜져 있으면 지금 언어로 다시 예약한다.
/// MyApp(Localizations 바깥)의 첫 프레임은 번역 로드 전이라 키 문자열이 그대로 들어간다.
/// 그래서 번역이 로드된 뒤에야 그려지는 MaterialApp.builder 안쪽에서 한 번만 실행한다.
class _ReminderResync extends ConsumerStatefulWidget {
  final Widget child;

  const _ReminderResync({required this.child});

  @override
  ConsumerState<_ReminderResync> createState() => _ReminderResyncState();
}

class _ReminderResyncState extends ConsumerState<_ReminderResync> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임을 막지 않게 그린 뒤에 시작하고 기다리지 않는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      if (!settings.reminderEnabled) return;
      syncReminder(ref.read(reminderServiceProvider), settings).catchError(
        (Object e) => debugPrint('알림 다시 예약 실패: $e'),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

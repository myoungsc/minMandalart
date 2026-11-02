import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandalart/core/providers/settings_provider.dart';

void main() {
  group('AppSettings 모델 테스트', () {
    test('AppSettings 기본 생성 테스트', () {
      final settings = AppSettings();

      expect(settings.themeMode, ThemeMode.light);
    });

    test('AppSettings 커스텀 값으로 생성 테스트', () {
      final settings = AppSettings(themeMode: ThemeMode.dark);

      expect(settings.themeMode, ThemeMode.dark);
    });

    test('AppSettings copyWith 테스트 - themeMode 변경', () {
      final settings = AppSettings();
      final updatedSettings = settings.copyWith(themeMode: ThemeMode.dark);

      expect(updatedSettings.themeMode, ThemeMode.dark);
      expect(settings.themeMode, ThemeMode.light); // 원본은 변경되지 않음
    });

    test('AppSettings copyWith 테스트 - 값 변경 없음', () {
      final settings = AppSettings(themeMode: ThemeMode.system);
      final updatedSettings = settings.copyWith();

      expect(updatedSettings.themeMode, ThemeMode.system);
    });
  });

  group('SettingsNotifier 테스트', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 light 모드여야 함', () {
      final state = container.read(settingsProvider);

      expect(state.themeMode, ThemeMode.light);
    });

    test('setThemeMode로 dark 모드 설정 테스트', () {
      final notifier = container.read(settingsProvider.notifier);
      notifier.setThemeMode(ThemeMode.dark);

      final state = container.read(settingsProvider);
      expect(state.themeMode, ThemeMode.dark);
    });

    test('setThemeMode로 system 모드 설정 테스트', () {
      final notifier = container.read(settingsProvider.notifier);
      notifier.setThemeMode(ThemeMode.system);

      final state = container.read(settingsProvider);
      expect(state.themeMode, ThemeMode.system);
    });

    test('여러 번 테마 모드 변경 테스트', () {
      final notifier = container.read(settingsProvider.notifier);

      // light -> dark
      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

      // dark -> system
      notifier.setThemeMode(ThemeMode.system);
      expect(container.read(settingsProvider).themeMode, ThemeMode.system);

      // system -> light
      notifier.setThemeMode(ThemeMode.light);
      expect(container.read(settingsProvider).themeMode, ThemeMode.light);
    });

    test('동일한 테마 모드로 여러 번 설정해도 동작해야 함', () {
      final notifier = container.read(settingsProvider.notifier);

      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    });
  });

  group('settingsProvider 통합 테스트', () {
    test('여러 ProviderContainer에서 독립적으로 동작해야 함', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();

      final notifier1 = container1.read(settingsProvider.notifier);
      final notifier2 = container2.read(settingsProvider.notifier);

      notifier1.setThemeMode(ThemeMode.dark);
      notifier2.setThemeMode(ThemeMode.system);

      expect(container1.read(settingsProvider).themeMode, ThemeMode.dark);
      expect(container2.read(settingsProvider).themeMode, ThemeMode.system);

      container1.dispose();
      container2.dispose();
    });
  });
}

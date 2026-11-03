import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

/// 앱 시작 때 main에서 채운다. 없으면 저장 없이 메모리에서만 동작한다.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

class AppSettings {
  final ThemeMode themeMode;

  AppSettings({
    this.themeMode = ThemeMode.light,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences? _prefs;

  SettingsNotifier([this._prefs])
    : super(AppSettings(themeMode: _readThemeMode(_prefs)));

  static ThemeMode _readThemeMode(SharedPreferences? prefs) {
    final saved = prefs?.getString(_themeModeKey);
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs?.setString(_themeModeKey, mode.name);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

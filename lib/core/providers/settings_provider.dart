import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';
const _reminderEnabledKey = 'reminder_enabled';
// 하루 중 분(0~1439)으로 저장한다.
const _reminderMinutesKey = 'reminder_minutes';

const defaultReminderTime = TimeOfDay(hour: 21, minute: 0);

/// 앱 시작 때 main에서 채운다. 없으면 저장 없이 메모리에서만 동작한다.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

class AppSettings {
  final ThemeMode themeMode;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;

  AppSettings({
    this.themeMode = ThemeMode.light,
    this.reminderEnabled = false,
    this.reminderTime = defaultReminderTime,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences? _prefs;

  SettingsNotifier([this._prefs])
    : super(AppSettings(
        themeMode: _readThemeMode(_prefs),
        reminderEnabled: _prefs?.getBool(_reminderEnabledKey) ?? false,
        reminderTime: _readReminderTime(_prefs),
      ));

  static ThemeMode _readThemeMode(SharedPreferences? prefs) {
    final saved = prefs?.getString(_themeModeKey);
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.light;
  }

  static TimeOfDay _readReminderTime(SharedPreferences? prefs) {
    final minutes = prefs?.getInt(_reminderMinutesKey);
    if (minutes == null || minutes < 0 || minutes >= 24 * 60) {
      return defaultReminderTime;
    }
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs?.setString(_themeModeKey, mode.name);
  }

  void setReminderEnabled(bool enabled) {
    state = state.copyWith(reminderEnabled: enabled);
    _prefs?.setBool(_reminderEnabledKey, enabled);
  }

  void setReminderTime(TimeOfDay time) {
    state = state.copyWith(reminderTime: time);
    _prefs?.setInt(_reminderMinutesKey, time.hour * 60 + time.minute);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

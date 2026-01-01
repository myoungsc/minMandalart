import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  SettingsNotifier() : super(AppSettings());

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

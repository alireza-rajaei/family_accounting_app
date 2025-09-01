import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final double fontScale;
  final String username;
  final DateTime? lastLoginAt;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontScale = 1.0,
    this.username = 'ادمین',
    this.lastLoginAt,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    String? username,
    DateTime? lastLoginAt,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      username: username ?? this.username,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [themeMode, fontScale, username, lastLoginAt];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  static const _keyThemeMode = 'settings.theme_mode';
  static const _keyFontScale = 'settings.font_scale';
  static const _keyUsername = 'settings.username';
  static const _keyLastLoginAt = 'settings.last_login_at';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    final fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;
    final username = prefs.getString(_keyUsername) ?? 'ادمین';
    final last = prefs.getString(_keyLastLoginAt);
    emit(state.copyWith(
      themeMode: themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.system,
      fontScale: fontScale,
      username: username,
      lastLoginAt: last != null ? DateTime.tryParse(last) : null,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, scale);
    emit(state.copyWith(fontScale: scale));
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    emit(state.copyWith(username: username));
  }

  Future<void> setLastLogin(DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastLoginAt, when.toIso8601String());
    emit(state.copyWith(lastLoginAt: when));
  }
}



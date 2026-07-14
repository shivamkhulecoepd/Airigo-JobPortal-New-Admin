// ============================================================
// core/providers/theme_provider.dart
// ============================================================
import 'package:airigo_jobportal/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefKeyTheme);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    // ignore: curly_braces_in_flow_control_structures
    } else if (saved == 'light') state = ThemeMode.light;
    // ignore: curly_braces_in_flow_control_structures
    else state = ThemeMode.system;
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyTheme, mode.name);
  }
}
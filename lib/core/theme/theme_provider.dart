import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MeloraThemeMode { system, dark, light }

class ThemeNotifier extends StateNotifier<MeloraThemeMode> {
  ThemeNotifier() : super(MeloraThemeMode.dark) {
    _loadTheme();
  }

  static const String _themeKey = 'melora_theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 1; // default dark
    state = MeloraThemeMode.values[index];
  }

  Future<void> setTheme(MeloraThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  ThemeMode get themeMode {
    switch (state) {
      case MeloraThemeMode.system:
        return ThemeMode.system;
      case MeloraThemeMode.dark:
        return ThemeMode.dark;
      case MeloraThemeMode.light:
        return ThemeMode.light;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, MeloraThemeMode>((
  ref,
) {
  return ThemeNotifier();
});

/// Helper to check if current theme is dark
final isDarkModeProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeProvider);
  return mode == MeloraThemeMode.dark || mode == MeloraThemeMode.system;
});

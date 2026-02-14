import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _boxKey = 'melora_theme_mode';

  @override
  ThemeMode build() {
    return _loadTheme();
  }

  ThemeMode get themeMode => state;

  ThemeMode _loadTheme() {
    final box = Hive.box('melora_settings');
    final value = box.get(_boxKey, defaultValue: 'dark');
    return switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = Hive.box('melora_settings');
    await box.put(_boxKey, mode.name);
  }

  void toggleTheme() {
    setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

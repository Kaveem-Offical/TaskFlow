import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    if (themeString == 'light') {
      state = ThemeMode.light;
    } else if (themeString == 'dark') state = ThemeMode.dark;
    else state = ThemeMode.system;
  }

  void setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    if (mode == ThemeMode.light) {
      themeString = 'light';
    } else if (mode == ThemeMode.dark) themeString = 'dark';
    prefs.setString('themeMode', themeString);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

class ThemeController {
  final mode = signal<ThemeMode>(ThemeMode.system);

  void setMode(ThemeMode value) {
    mode.value = value;
  }

  String labelFor(ThemeMode value) {
    switch (value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

final themeController = ThemeController();

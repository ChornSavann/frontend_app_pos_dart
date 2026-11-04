import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide dark mode. Saved in SharedPreferences so it survives restarts.
class ThemeController extends GetxController {
  static const String _key = 'is_dark_mode';

  bool isDark = false;

  ThemeMode get themeMode => isDark ? ThemeMode.dark : ThemeMode.light;

  /// Call once before runApp so the first frame already uses the saved theme.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool(_key) ?? false;
  }

  Future<void> setDark(bool value) async {
    isDark = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    update();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', value);
  }

  // ───────────── Themes ─────────────

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFFF4F6FB),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blueAccent,
    scaffoldBackgroundColor: const Color(0xFF0B1120),
    cardColor: const Color(0xFF151C2E),
  );
}
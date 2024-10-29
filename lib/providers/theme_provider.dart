import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get theme => _isDarkMode ? _darkTheme : _lightTheme;

  static final _lightTheme = ThemeData(
    primaryColor: const Color(0xFF2196F3),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF2196F3),
      secondary: Colors.blue[300]!,
      surface: Colors.white,
      background: const Color(0xFFE3F2FD),
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
    ),
  );

  static final _darkTheme = ThemeData(
    primaryColor: const Color(0xFF2196F3),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF2196F3),
      secondary: Colors.blue[300]!,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      error: Colors.red[700]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme {
    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
        brightness: Brightness.dark,
        primaryColor: Colors.brown[200],
        scaffoldBackgroundColor: const Color(0xFF181818),
        cardColor: const Color(0xFF232323),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF232323),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: Colors.white,
            fontSize: 22,
          ),
          displaySmall: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          titleSmall: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
          bodyLarge: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          bodySmall: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          labelLarge: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          labelMedium: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          labelSmall: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.brown[200],
          size: 28,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF232323),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[200],
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF232323),
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.brown),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF232323),
          selectedItemColor: Colors.brown[200],
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontSize: 12, color: Colors.white),
          unselectedLabelStyle: const TextStyle(fontSize: 12, color: Colors.white70),
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.white24,
          thickness: 1,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF232323),
          textStyle: TextStyle(color: Colors.white),
        ),
      );
    }

    // Giữ nguyên theme sáng mặc định
    return ThemeData.light().copyWith(
      primaryColor: Colors.brown[600],
      scaffoldBackgroundColor: Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: Color(0xFF2C2C2C),
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF4A4A4A),
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF2C2C2C),
          fontSize: 16,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[600],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(THEME_KEY) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, _isDarkMode);
    notifyListeners();
  }
}

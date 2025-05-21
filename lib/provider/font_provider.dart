import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontProvider extends ChangeNotifier {
  static const String FONT_KEY = 'font_family';
  String _currentFont = 'Dancing Script'; // Thay đổi font mặc định thành Poppins

  FontProvider() {
    _loadSavedFont();
  }

  String get currentFont => _currentFont;

  final List<String> availableFonts = ['Roboto', 'Open Sans', 'Poppins'];

  Future<void> _loadSavedFont() async {
    final prefs = await SharedPreferences.getInstance();
    _currentFont = prefs.getString(FONT_KEY) ?? 'Poppins'; // Sửa mặc định thành 'Poppins'
    notifyListeners();
  }

  Future<void> setFont(String font) async {
    if (!availableFonts.contains(font)) return;
    _currentFont = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(FONT_KEY, font);
    notifyListeners();
  }

  TextTheme get textTheme => TextTheme(
        bodyLarge: TextStyle(fontFamily: _currentFont),
        bodyMedium: TextStyle(fontFamily: _currentFont),
        titleLarge: TextStyle(fontFamily: _currentFont),
        // Add more text styles as needed
      );
}

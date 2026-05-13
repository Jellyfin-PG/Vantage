import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'prefs.dart';
import '../models/nasa_theme.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();
  ThemeService._internal();

  final _prefs = Prefs();
  
  NasaTheme _currentTheme = NasaTheme.defaultDark;
  final List<NasaTheme> _allThemes = [
    NasaTheme.defaultLight,
    NasaTheme.defaultDark,
  ];

  NasaTheme get currentTheme => _currentTheme;
  List<NasaTheme> get allThemes => _allThemes;

  Future<void> init() async {
    await scanForThemes();
    final savedId = await _prefs.currentThemeId;
    _currentTheme = _allThemes.firstWhere(
      (t) => t.id == savedId,
      orElse: () => NasaTheme.defaultDark,
    );
    notifyListeners();
  }

  Future<void> scanForThemes() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final themeDir = Directory('${docDir.path}/Vantage/themes');
      
      if (!await themeDir.exists()) {
        await themeDir.create(recursive: true);
        return;
      }

      final files = themeDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
      
      
      _allThemes.clear();
      _allThemes.add(NasaTheme.defaultLight);
      _allThemes.add(NasaTheme.defaultDark);

      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content);
          final theme = NasaTheme.fromJson(json);
          
          
          if (!_allThemes.any((t) => t.id == theme.id)) {
            _allThemes.add(theme);
          }
        } catch (e) {
          debugPrint('Error parsing theme file \${file.path}: \$e');
        }
      }
    } catch (e) {
      debugPrint('Error scanning for themes: \$e');
    }
  }

  Future<void> setTheme(NasaTheme theme) async {
    _currentTheme = theme;
    await _prefs.setCurrentThemeId(theme.id);
    notifyListeners();
  }

  bool get isDarkMode => _currentTheme.brightness == Brightness.dark;
}


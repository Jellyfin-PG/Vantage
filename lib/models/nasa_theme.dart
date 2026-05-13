import 'package:flutter/material.dart';

class NasaTheme {
  final String id;
  final String name;
  final Color background;
  final Color primary;
  final Color surface;
  final Color text;
  final double gridOpacity;
  final Brightness brightness;

  NasaTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.primary,
    required this.surface,
    required this.text,
    required this.gridOpacity,
    required this.brightness,
  });

  factory NasaTheme.fromJson(Map<String, dynamic> json) {
    return NasaTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      background: _parseColor(json['background'] as String),
      primary: _parseColor(json['primary'] as String),
      surface: _parseColor(json['surface'] as String),
      text: _parseColor(json['text'] as String),
      gridOpacity: (json['gridOpacity'] as num).toDouble(),
      brightness: (json['brightness'] as String) == 'dark' ? Brightness.dark : Brightness.light,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'background': _toHex(background),
      'primary': _toHex(primary),
      'surface': _toHex(surface),
      'text': _toHex(text),
      'gridOpacity': gridOpacity,
      'brightness': brightness == Brightness.dark ? 'dark' : 'light',
    };
  }

  static Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static final NasaTheme defaultLight = NasaTheme(
    id: 'nasa_white',
    name: 'NASA_WHITE',
    background: const Color(0xFFF0F0F2),
    primary: const Color(0xFFFF5C00),
    surface: Colors.white,
    text: const Color(0xFF1A1A1A),
    gridOpacity: 0.02,
    brightness: Brightness.light,
  );

  static final NasaTheme defaultDark = NasaTheme(
    id: 'nasa_dark',
    name: 'NASA_DARK',
    background: const Color(0xFF121212),
    primary: const Color(0xFFFF5C00),
    surface: const Color(0xFF1E1E1E),
    text: Colors.white,
    gridOpacity: 0.02,
    brightness: Brightness.dark,
  );
}

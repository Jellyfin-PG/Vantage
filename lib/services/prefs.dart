



import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Prefs {
  static const _serverUrlKey = 'server_url';
  static const _tokenKey = 'token';
  static const _userIdKey = 'user_id';
  static const _themeIdKey = 'theme_id';

  final FlutterSecureStorage _storage;

  Prefs()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<String> get serverUrl async =>
      await _storage.read(key: _serverUrlKey) ?? '';

  Future<void> setServerUrl(String v) =>
      _storage.write(key: _serverUrlKey, value: v);

  Future<String> get token async =>
      await _storage.read(key: _tokenKey) ?? '';

  Future<void> setToken(String v) =>
      _storage.write(key: _tokenKey, value: v);

  Future<String> get userId async =>
      await _storage.read(key: _userIdKey) ?? '';

  Future<void> setUserId(String v) =>
      _storage.write(key: _userIdKey, value: v);

  Future<String> get currentThemeId async =>
      await _storage.read(key: _themeIdKey) ?? 'nasa_dark';

  Future<void> setCurrentThemeId(String v) =>
      _storage.write(key: _themeIdKey, value: v);

  Future<bool> get isLoggedIn async {
    final url = await serverUrl;
    final tok = await token;
    return url.isNotEmpty && tok.isNotEmpty;
  }

  static const _keyMapKey = 'key_map_json';
  static const _gamepadMapKey = 'gamepad_map_json';

  Future<String?> get keyMapJson async => await _storage.read(key: _keyMapKey);
  Future<void> setKeyMapJson(String v) => _storage.write(key: _keyMapKey, value: v);

  Future<String?> get gamepadMapJson async => await _storage.read(key: _gamepadMapKey);
  Future<void> setGamepadMapJson(String v) => _storage.write(key: _gamepadMapKey, value: v);

  Future<void> logout() => _storage.deleteAll();
}


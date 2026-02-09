import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _serverUrlKey = 'server_url';
  static const String _passwordKey = 'password';

  final SharedPreferences? _prefs;

  StorageService(this._prefs);

  Future<void> saveServerUrl(String url) async {
    await _prefs?.setString(_serverUrlKey, url);
  }

  String? getServerUrl() {
    return _prefs?.getString(_serverUrlKey);
  }

  Future<void> savePassword(String password) async {
    await _prefs?.setString(_passwordKey, password);
  }

  String? getPassword() {
    return _prefs?.getString(_passwordKey);
  }

  Future<void> clearAll() async {
    await _prefs?.remove(_serverUrlKey);
    await _prefs?.remove(_passwordKey);
  }

  bool hasCredentials() {
    return getServerUrl() != null && getPassword() != null;
  }
}

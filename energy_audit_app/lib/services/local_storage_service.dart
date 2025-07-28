import 'package:shared_preferences/shared_preferences.dart';

/// Simple key/value storage for flags & small data.
class LocalStorageService {
  /// Save a boolean under [key]
  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Read a boolean for [key], defaulting to false
  Future<bool> readBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Very simple local auth:
/// - Registry: StringList under key 'users_registry'
/// - Passwords: per-user 'pwd_<username>' (plain text for dev; swap to hash later)
class AuthService {
  /*static const _kRegistryKey = 'users_registry';
  static String _pwdKey(String u) => 'pwd_$u';

  /// Return all registered usernames.
  Future<List<String>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.from(prefs.getStringList(_kRegistryKey) ?? const []);
  }

  Future<bool> _userExists(String username) async {
    final list = await getAllUsers();
    return list.contains(username);
  }

  /// Register new user. Returns false if username already exists.
  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(prefs.getStringList(_kRegistryKey) ?? const []);
    if (list.contains(username)) return false;

    list.add(username);
    await prefs.setStringList(_kRegistryKey, list);
    await prefs.setString(_pwdKey(username), password);
    return true;
  }

  /// Validate login credentials.
  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await _userExists(username)) return false;
    final stored = prefs.getString(_pwdKey(username));
    return stored == password;
  }

  /// Delete a single user (registry entry + stored password).
  Future<void> deleteUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(prefs.getStringList(_kRegistryKey) ?? const []);
    list.remove(username);
    await prefs.setStringList(_kRegistryKey, list);
    await prefs.remove(_pwdKey(username));
  }

  /// Danger: clear ALL local users and all SharedPreferences.
  /// Used by "Clear ALL users & data" in Account.
  Future<void> clearAll() async {
    // For simplicity in dev, nuke everything in SharedPreferences.
    await SettingsService().clearAll();
  }*/

  //experimental new database impementation
  final _supabase = Supabase.instance.client;

  Future<AuthResponse> register(String email, String password) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return res;
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Future<List<String>> getAllUsers() async {
    try {
      // For now, return only the logged-in user’s email.
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      return [user.email ?? ''];
    } catch (e) {
      print('getAllUsers error: $e');
      return [];
    }
  }

  Future<void> clearAll() async {
    await SettingsService().clearAll();
  }
}

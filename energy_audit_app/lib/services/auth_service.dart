import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Very simple auth service backed by FlutterSecureStorage.
/// - Key "users" holds a JSON array of usernames.
/// - Key "user:<username>" holds a hex(SHA-256(password)).
/// This is NOT production-grade auth; it's sufficient for local demo/testing.
class AuthService {
  static const _kUsersKey = 'users';
  static const _kUserPrefix = 'user:'; // user:<username>

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<List<String>> getAllUsers() async {
    final s = await _secure.read(key: _kUsersKey);
    if (s == null || s.trim().isEmpty) return [];
    final decoded = json.decode(s);
    if (decoded is List) {
      return decoded.whereType<String>().toList();
    }
    return [];
  }

  Future<bool> register(String username, String password) async {
    final users = await getAllUsers();
    if (users.contains(username)) return false;

    final hash = _hash(password);
    await _secure.write(key: '$_kUserPrefix$username', value: hash);

    users.add(username);
    await _secure.write(key: _kUsersKey, value: json.encode(users));
    return true;
  }

  Future<bool> login(String username, String password) async {
    final users = await getAllUsers();
    if (!users.contains(username)) return false;
    final stored = await _secure.read(key: '$_kUserPrefix$username');
    if (stored == null) return false;
    return stored == _hash(password);
  }

  /// Remove all registered users and credentials from secure storage.
  Future<void> clearAllUsers() async {
    final users = await getAllUsers();
    for (final u in users) {
      await _secure.delete(key: '$_kUserPrefix$u');
    }
    await _secure.delete(key: _kUsersKey);
    if (kDebugMode) {
      // Optional: log
    }
  }

  String _hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Handles user credentials in secure storage (mobile only).
class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accountsKey = 'accounts_list';

  /// Get all registered usernames.
  Future<List<String>> getAllUsers() async {
    final jsonStr = await _storage.read(key: _accountsKey);
    if (jsonStr == null) return [];
    return List<String>.from(json.decode(jsonStr) as List);
  }

  /// Register a new user. Returns false if username already exists.
  Future<bool> register(String username, String password) async {
    final users = await getAllUsers();
    if (users.contains(username)) return false;

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final cred = json.encode({'salt': salt, 'hash': hash});
    await _storage.write(key: 'user_$username', value: cred);

    users.add(username);
    await _storage.write(key: _accountsKey, value: json.encode(users));
    return true;
  }

  /// Attempt login. Returns true if credentials match.
  Future<bool> login(String username, String password) async {
    final credJson = await _storage.read(key: 'user_$username');
    if (credJson == null) return false;

    final data = json.decode(credJson) as Map<String, dynamic>;
    final salt = data['salt'] as String;
    final storedHash = data['hash'] as String;
    final inputHash = _hashPassword(password, salt);
    return inputHash == storedHash;
  }

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    return sha256.convert(bytes).toString();
  }
}

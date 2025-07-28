import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'credential_storage.dart';

class AuthService {
  final CredentialStorage _storage = CredentialStorage();
  static const _accountsKey = 'accounts_list';

  /// Load all registered usernames
  Future<List<String>> _loadUsernames() async {
    final jsonStr = await _storage.read(_accountsKey);
    if (jsonStr == null) return [];
    return List<String>.from(json.decode(jsonStr) as List);
  }

  /// Persist username list
  Future<void> _saveUsernames(List<String> users) async {
    await _storage.write(_accountsKey, json.encode(users));
  }

  /// Generate random salt (16 bytes)
  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash password with salt using SHA-256
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    return sha256.convert(bytes).toString();
  }

  /// Register new user. Returns false if username already exists.
  Future<bool> register(String username, String password) async {
    final users = await _loadUsernames();
    if (users.contains(username)) return false;

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    final cred = json.encode({'salt': salt, 'hash': hash});
    await _storage.write('user_$username', cred);

    users.add(username);
    await _saveUsernames(users);
    return true;
  }

  /// Attempt login. Returns true if credentials match.
  Future<bool> login(String username, String password) async {
    final credJson = await _storage.read('user_$username');
    if (credJson == null) return false;

    final data = json.decode(credJson) as Map<String, dynamic>;
    final salt = data['salt'] as String;
    final storedHash = data['hash'] as String;
    final inputHash = _hashPassword(password, salt);
    return inputHash == storedHash;
  }
}

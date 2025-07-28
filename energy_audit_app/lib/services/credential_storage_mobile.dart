import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mobile implementation using flutter_secure_storage
class CredentialStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

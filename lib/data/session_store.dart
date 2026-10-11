import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SessionStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> writeToken(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemorySessionStore implements SessionStore {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

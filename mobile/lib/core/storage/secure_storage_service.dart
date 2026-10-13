import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token persistence. Prefer [memory] in unit/integration tests where
/// platform secure storage channels are unavailable.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
    Map<String, String>? memory,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _memory = memory;

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;
  final Map<String, String>? _memory;

  Future<void> saveToken(String token) async {
    if (_memory != null) {
      _memory[_tokenKey] = token;
      return;
    }

    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Platform channel unavailable in some test environments.
    }
  }

  Future<String?> readToken() async {
    if (_memory != null) {
      return _memory[_tokenKey];
    }

    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() async {
    if (_memory != null) {
      _memory.remove(_tokenKey);
      return;
    }

    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Ignore storage failures during logout/cleanup.
    }
  }
}

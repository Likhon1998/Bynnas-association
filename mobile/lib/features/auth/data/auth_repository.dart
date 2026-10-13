import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi authApi,
    required SecureStorageService secureStorage,
  })  : _authApi = authApi,
        _secureStorage = secureStorage;

  final AuthApi _authApi;
  final SecureStorageService _secureStorage;

  Future<AuthUser?> restoreSession() async {
    final token = await _secureStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final user = await _authApi.me();
      if (!user.isActive) {
        await _secureStorage.clearToken();
        return null;
      }
      return user;
    } catch (_) {
      await _secureStorage.clearToken();
      return null;
    }
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _authApi.login(email: email, password: password);
    await _secureStorage.saveToken(result.token);
    return result.user;
  }

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } finally {
      await _secureStorage.clearToken();
    }
  }

  Future<void> logoutAll() async {
    try {
      await _authApi.logoutAll();
    } finally {
      await _secureStorage.clearToken();
    }
  }

  Future<String> forgotPassword(String email) {
    return _authApi.forgotPassword(email);
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) {
    return _authApi.resetPassword(
      email: email,
      token: token,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}

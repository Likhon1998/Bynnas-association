import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(
    authApi: AuthApi(apiClient),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthUser?> build() {
    return _repository.restoreSession();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.login(email: email, password: password),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.logout();
      return null;
    });
  }

  Future<void> logoutAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.logoutAll();
      return null;
    });
  }

  Future<String> forgotPassword(String email) {
    return _repository.forgotPassword(email);
  }
}

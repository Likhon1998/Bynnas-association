import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../domain/auth_user.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<({String token, AuthUser user})> login({
    required String email,
    required String password,
    String deviceName = 'flutter-app',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );

      final data = response.data ?? {};
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        throw const AppException('Invalid login response from server.');
      }

      return (token: token, user: AuthUser.fromJson(userJson));
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<AuthUser> me() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/auth/me');
      final payload = response.data ?? {};
      final userJson = payload['data'] as Map<String, dynamic>? ?? payload;
      return AuthUser.fromJson(userJson);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<void> logout() async {
    try {
      await _client.post<Map<String, dynamic>>('/auth/logout');
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<void> logoutAll() async {
    try {
      await _client.post<Map<String, dynamic>>('/auth/logout-all');
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return response.data?['message'] as String? ??
          'Password reset link sent if the account exists.';
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response.data?['message'] as String? ?? 'Password has been reset.';
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  AppException _toAppException(DioException error) {
    final nested = error.error;
    if (nested is AppException) {
      return nested;
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return AppException(
            first.first.toString(),
            statusCode: error.response?.statusCode,
          );
        }
      }
      if (data['message'] is String) {
        return AppException(
          data['message'] as String,
          statusCode: error.response?.statusCode,
        );
      }
    }

    return AppException(
      error.message ?? 'Request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}

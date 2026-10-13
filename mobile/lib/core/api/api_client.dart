import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../error/app_exception.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  ApiClient({
    required SecureStorageService secureStorage,
    Dio? dio,
    String? baseUrl,
  })  : _secureStorage = secureStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(_mapError(error));
        },
      ),
    );
  }

  final Dio _dio;
  final SecureStorageService _secureStorage;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
  }) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
  }) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
  }) {
    return _dio.delete<T>(path, data: data);
  }

  DioException _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error.response?.data);

    final fallback = switch (statusCode) {
      401 => 'Unauthorized. Please sign in again.',
      403 => 'You do not have permission for this action.',
      404 => 'Requested resource was not found.',
      422 => 'Validation failed. Check your input.',
      500 => 'Server error. Please try again later.',
      _ => error.message ?? 'Unexpected network error.',
    };

    final message = serverMessage ?? fallback;

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: statusCode == 401
          ? UnauthorizedException(message)
          : NetworkException(message, statusCode: statusCode),
      message: message,
    );
  }

  String? _extractServerMessage(dynamic data) {
    if (data is! Map) {
      return null;
    }

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }

    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }
}

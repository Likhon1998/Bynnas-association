import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../domain/app_notification.dart';

class NotificationApi {
  NotificationApi(this._client);

  final ApiClient _client;

  Future<PaginatedNotifications> list({int page = 1, int perPage = 20}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final payload = response.data ?? {};
      final data = payload['data'];
      final meta = payload['meta'] as Map<String, dynamic>? ?? {};
      final items = data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(AppNotification.fromJson)
              .toList()
          : <AppNotification>[];

      return PaginatedNotifications(
        items: items,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
        lastPage: (meta['last_page'] as num?)?.toInt() ?? page,
        total: (meta['total'] as num?)?.toInt() ?? items.length,
      );
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/notifications/unread-count');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<AppNotification> markRead(int id) async {
    try {
      final response = await _client
          .post<Map<String, dynamic>>('/notifications/$id/read');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return AppNotification.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _client.post<Map<String, dynamic>>('/notifications/read-all');
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceName,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/device-tokens',
        data: {
          'token': token,
          'platform': platform,
          'device_name': ?deviceName,
        },
      );
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
    if (data is Map && data['message'] is String) {
      return AppException(
        data['message'] as String,
        statusCode: error.response?.statusCode,
      );
    }
    return AppException(
      error.message ?? 'Request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}

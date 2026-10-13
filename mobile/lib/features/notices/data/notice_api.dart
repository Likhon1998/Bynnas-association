import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../domain/notice.dart';

class NoticeApi {
  NoticeApi(this._client);

  final ApiClient _client;

  Future<List<Notice>> list({int page = 1, int perPage = 20}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/notices',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final payload = response.data ?? {};
      final data = payload['data'];
      if (data is! List) {
        return const [];
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(Notice.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Notice> show(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/notices/$id');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Notice.fromJson(data);
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

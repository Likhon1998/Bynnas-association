import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../domain/member.dart';

class MemberApi {
  MemberApi(this._client);

  final ApiClient _client;

  Future<Member> me() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/members/me');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Member.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Member> updateMe({
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      final me = await this.me();
      final response = await _client.put<Map<String, dynamic>>(
        '/members/${me.id}',
        data: {
          'name': ?name,
          'phone': ?phone,
          'address': ?address,
        },
      );
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Member.fromJson(data);
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

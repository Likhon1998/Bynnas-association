import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../domain/member_balance.dart';
import '../domain/member_due.dart';
import '../domain/member_payment.dart';

/// Member-facing finance reads against `/api/v1`.
/// Authorization is always server-side for the authenticated member.
class FinanceApi {
  FinanceApi(this._client);

  final ApiClient _client;

  Future<MemberBalance> myBalance() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/balances/me');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return MemberBalance.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<List<MemberDue>> myDues({int page = 1, int perPage = 20}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/dues',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final payload = response.data ?? {};
      final data = payload['data'];
      if (data is! List) {
        return const [];
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(MemberDue.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<List<MemberPayment>> myPayments({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/payments',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final payload = response.data ?? {};
      final data = payload['data'];
      if (data is! List) {
        return const [];
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(MemberPayment.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<MemberPayment> paymentDetail(int id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/payments/$id');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return MemberPayment.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<MemberStatement> myStatement({String? from, String? to}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/statements/me',
        queryParameters: {
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
        },
      );
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return MemberStatement.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  AppException _toAppException(DioException error) {
    final nested = error.error;
    if (nested is AppException) {
      return nested;
    }
    return AppException(
      error.message ?? 'Request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}

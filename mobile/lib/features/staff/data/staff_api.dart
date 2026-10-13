import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/error/app_exception.dart';
import '../../members/domain/member.dart';
import '../../notices/domain/notice.dart';

/// Staff-facing API reads/writes — all association ops from the mobile app.
class StaffApi {
  StaffApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> dashboard({String? from, String? to}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/dashboard',
        queryParameters: {
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
        },
      );
      final payload = response.data ?? {};
      return payload['data'] as Map<String, dynamic>? ?? payload;
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<List<Member>> listMembers({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/members',
        queryParameters: {
          'page': page,
          'per_page': 30,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data?['data'];
      if (data is! List) {
        return const [];
      }
      return data.whereType<Map<String, dynamic>>().map(Member.fromJson).toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Member> memberDetail(int id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/members/$id');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Member.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  /// Returns `{member, temporaryPassword?}`.
  Future<({Member member, String? temporaryPassword})> createMember({
    required String name,
    required String email,
    String? password,
    String? passwordConfirmation,
    String? phone,
    String? address,
    String? notes,
    String? joinedOn,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/members',
        data: {
          'name': name,
          'email': email,
          if (password != null && password.isNotEmpty) ...{
            'password': password,
            'password_confirmation': passwordConfirmation ?? password,
          },
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (address != null && address.isNotEmpty) 'address': address,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (joinedOn != null && joinedOn.isNotEmpty) 'joined_on': joinedOn,
        },
      );
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (
        member: Member.fromJson(data),
        temporaryPassword: payload['temporary_password'] as String?,
      );
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Member> updateMember(
    int id, {
    String? name,
    String? email,
    String? phone,
    String? address,
    String? notes,
    String? joinedOn,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/members/$id',
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (notes != null) 'notes': notes,
          if (joinedOn != null) 'joined_on': joinedOn,
          if (password != null && password.isNotEmpty) ...{
            'password': password,
            'password_confirmation': passwordConfirmation ?? password,
          },
        },
      );
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Member.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Member> deactivateMember(int id) async {
    try {
      final response =
          await _client.post<Map<String, dynamic>>('/members/$id/deactivate');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Member.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Member> reactivateMember(int id) async {
    try {
      final response =
          await _client.post<Map<String, dynamic>>('/members/$id/reactivate');
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Member.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> memberBalance(int id) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/balances/$id');
      final payload = response.data ?? {};
      return payload['data'] as Map<String, dynamic>? ?? payload;
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<List<Map<String, dynamic>>> listPlans({bool? activeOnly}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/contribution-plans',
        queryParameters: {
          'per_page': 50,
          if (activeOnly != null) 'active': activeOnly,
        },
      );
      final data = response.data?['data'];
      if (data is! List) {
        return const [];
      }
      return data.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> createPlan({
    required String name,
    required String code,
    required String defaultAmount,
    String? description,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/contribution-plans',
        data: {
          'name': name,
          'code': code,
          'default_amount': defaultAmount,
          if (description != null && description.isNotEmpty)
            'description': description,
          'currency': 'BDT',
          'is_active': true,
        },
      );
      final payload = response.data ?? {};
      return payload['data'] as Map<String, dynamic>? ?? payload;
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> generateDues({
    required int year,
    required int month,
    int? contributionPlanId,
    int? userId,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/dues/generate',
        data: {
          'year': year,
          'month': month,
          if (contributionPlanId != null)
            'contribution_plan_id': contributionPlanId,
          if (userId != null) 'user_id': userId,
        },
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<List<Map<String, dynamic>>> listPayments({
    String? search,
    String? status,
    int page = 1,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/payments',
        queryParameters: {
          'page': page,
          'per_page': 30,
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      final data = response.data?['data'];
      if (data is! List) {
        return const [];
      }
      return data.whereType<Map<String, dynamic>>().toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> recordPayment({
    required int userId,
    required String amount,
    required String method,
    required String idempotencyKey,
    String? notes,
    List<Map<String, dynamic>>? allocations,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/payments',
        data: {
          'user_id': userId,
          'amount': amount,
          'method': method,
          'idempotency_key': idempotencyKey,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (allocations != null && allocations.isNotEmpty)
            'allocations': allocations,
        },
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> reversePayment({
    required int paymentId,
    required String reason,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/payments/$paymentId/reverse',
        data: {'reason': reason},
      );
      final payload = response.data ?? {};
      return payload['data'] as Map<String, dynamic>? ?? payload;
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> memberWiseReport({
    String? from,
    String? to,
    String? search,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/reports/member-wise',
        queryParameters: {
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
          if (search != null && search.isNotEmpty) 'search': search,
          'per_page': 50,
        },
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Map<String, dynamic>> monthWiseReport({
    String? from,
    String? to,
  }) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/reports/month-wise',
        queryParameters: {
          if (from != null && from.isNotEmpty) 'from': from,
          if (to != null && to.isNotEmpty) 'to': to,
          'per_page': 24,
        },
      );
      return response.data ?? {};
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<List<Map<String, dynamic>>> memberOpenDues(int userId) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/dues',
        queryParameters: {'user_id': userId, 'per_page': 50},
      );
      final data = response.data?['data'];
      if (data is! List) {
        return const [];
      }
      return data
          .whereType<Map<String, dynamic>>()
          .where((row) {
            final status = row['status']?.toString();
            return status != 'paid' && status != 'voided';
          })
          .toList();
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Notice> createNotice({
    required String title,
    required String body,
    String audienceType = 'all_active_members',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/notices',
        data: {
          'title': title,
          'body': body,
          'audience_type': audienceType,
        },
      );
      final payload = response.data ?? {};
      final data = payload['data'] as Map<String, dynamic>? ?? payload;
      return Notice.fromJson(data);
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }

  Future<Notice> publishNotice(int id) async {
    try {
      final response =
          await _client.post<Map<String, dynamic>>('/notices/$id/publish');
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
    if (data is Map) {
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

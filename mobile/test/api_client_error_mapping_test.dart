import 'dart:convert';

import 'package:bynnas_association/core/api/api_client.dart';
import 'package:bynnas_association/core/error/app_exception.dart';
import 'package:bynnas_association/core/storage/secure_storage_service.dart';
import 'package:bynnas_association/features/auth/data/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReplyAdapter implements HttpClientAdapter {
  _ReplyAdapter(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

void main() {
  test('login maps Laravel credential validation errors to AppException message',
      () async {
    final storage = SecureStorageService(memory: <String, String>{});
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api/v1'));
    dio.httpClientAdapter = _ReplyAdapter(422, {
      'message': 'The provided credentials are incorrect.',
      'errors': {
        'email': ['The provided credentials are incorrect.'],
      },
    });

    final api = AuthApi(ApiClient(secureStorage: storage, dio: dio));

    await expectLater(
      api.login(email: 'a@b.c', password: 'bad'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'The provided credentials are incorrect.',
        ),
      ),
    );
  });
}

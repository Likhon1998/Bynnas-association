import 'dart:io';

import 'package:bynnas_association/core/api/api_client.dart';
import 'package:bynnas_association/core/storage/secure_storage_service.dart';
import 'package:bynnas_association/features/auth/data/auth_api.dart';
import 'package:bynnas_association/features/auth/data/auth_repository.dart';
import 'package:bynnas_association/features/finance/data/finance_api.dart';
import 'package:bynnas_association/features/members/data/member_api.dart';
import 'package:bynnas_association/features/notices/data/notice_api.dart';
import 'package:bynnas_association/features/notices/data/notification_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared setup for Flutter ↔ Laravel HTTP integration tests.
///
/// Requires a prepared integration API (see `scripts/run-mobile-integration.ps1`).
/// Configure via:
/// - `--dart-define=API_BASE_URL=http://127.0.0.1:8765/api/v1`
/// - `--dart-define=INTEGRATION_MEMBER_EMAIL=...`
/// - `--dart-define=INTEGRATION_MEMBER_PASSWORD=...`
/// - `--dart-define=INTEGRATION_OTHER_MEMBER_EMAIL=...`
/// - `--dart-define=INTEGRATION_OTHER_MEMBER_PASSWORD=...`
class IntegrationHarness {
  IntegrationHarness._({
    required this.baseUrl,
    required this.memberEmail,
    required this.memberPassword,
    required this.otherMemberEmail,
    required this.otherMemberPassword,
    required this.storage,
    required this.client,
    required this.authRepository,
    required this.authApi,
    required this.memberApi,
    required this.noticeApi,
    required this.notificationApi,
    required this.financeApi,
  });

  final String baseUrl;
  final String memberEmail;
  final String memberPassword;
  final String otherMemberEmail;
  final String otherMemberPassword;
  final SecureStorageService storage;
  final ApiClient client;
  final AuthRepository authRepository;
  final AuthApi authApi;
  final MemberApi memberApi;
  final NoticeApi noticeApi;
  final NotificationApi notificationApi;
  final FinanceApi financeApi;

  static Future<IntegrationHarness?> createIfAvailable() async {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8765/api/v1',
    );
    const memberEmail = String.fromEnvironment(
      'INTEGRATION_MEMBER_EMAIL',
      defaultValue: 'integration.member@bynnas.test',
    );
    const memberPassword = String.fromEnvironment(
      'INTEGRATION_MEMBER_PASSWORD',
      defaultValue: 'password',
    );
    const otherEmail = String.fromEnvironment(
      'INTEGRATION_OTHER_MEMBER_EMAIL',
      defaultValue: 'integration.other@bynnas.test',
    );
    const otherPassword = String.fromEnvironment(
      'INTEGRATION_OTHER_MEMBER_PASSWORD',
      defaultValue: 'password',
    );

    final healthy = await _healthOk(baseUrl);
    if (!healthy) {
      return null;
    }

    final memory = <String, String>{};
    final storage = SecureStorageService(memory: memory);
    final client = ApiClient(secureStorage: storage, baseUrl: baseUrl);
    final authApi = AuthApi(client);

    return IntegrationHarness._(
      baseUrl: baseUrl,
      memberEmail: memberEmail,
      memberPassword: memberPassword,
      otherMemberEmail: otherEmail,
      otherMemberPassword: otherPassword,
      storage: storage,
      client: client,
      authRepository: AuthRepository(authApi: authApi, secureStorage: storage),
      authApi: authApi,
      memberApi: MemberApi(client),
      noticeApi: NoticeApi(client),
      notificationApi: NotificationApi(client),
      financeApi: FinanceApi(client),
    );
  }

  Future<void> loginAsMember() {
    return authRepository.login(email: memberEmail, password: memberPassword);
  }

  Future<void> loginAsOtherMember() {
    return authRepository.login(
      email: otherMemberEmail,
      password: otherMemberPassword,
    );
  }

  Future<void> clearSession() => storage.clearToken();

  static Future<bool> _healthOk(String baseUrl) async {
    final root = baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ),
    );
    try {
      final response = await dio.get<Map<String, dynamic>>('$root/api/v1/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

void skipIfApiUnavailable(IntegrationHarness? harness) {
  if (harness == null) {
    // ignore: avoid_print
    print(
      'SKIP: Laravel integration API unavailable. '
      'Run scripts/run-mobile-integration.ps1 (or start the integration server).',
    );
  }
}

/// Marks a suite that must talk to the live integration API.
void integrationTest(
  String description,
  Future<void> Function(IntegrationHarness harness) body,
) {
  test(description, () async {
    final harness = await IntegrationHarness.createIfAvailable();
    skipIfApiUnavailable(harness);
    if (harness == null) {
      return;
    }

    addTearDown(() async {
      await harness.clearSession();
    });

    await body(harness);
  }, timeout: const Timeout(Duration(seconds: 60)));
}

bool get isCi {
  return Platform.environment['CI'] == 'true' ||
      Platform.environment['GITHUB_ACTIONS'] == 'true';
}

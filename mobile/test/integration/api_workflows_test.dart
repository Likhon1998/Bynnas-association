import 'dart:io';

import 'package:bynnas_association/core/api/api_client.dart';
import 'package:bynnas_association/core/error/app_exception.dart';
import 'package:bynnas_association/core/storage/secure_storage_service.dart';
import 'package:bynnas_association/features/auth/data/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/integration_harness.dart';

void main() {
  IntegrationHarness? harness;

  setUpAll(() async {
    harness = await IntegrationHarness.createIfAvailable();
    final requireApi = Platform.environment['REQUIRE_INTEGRATION_API'] == '1' ||
        const bool.fromEnvironment('REQUIRE_INTEGRATION_API');

    if (harness == null && requireApi) {
      fail(
        'Laravel integration API is required but unreachable. '
        'Start it with scripts/run-mobile-integration.ps1',
      );
    }
  });

  tearDown(() async {
    await harness?.clearSession();
  });

  bool requireHarness() {
    if (harness == null) {
      markTestSkipped(
        'Laravel integration API unavailable. '
        'Run scripts/run-mobile-integration.ps1',
      );
      return false;
    }
    return true;
  }

  test('login with valid credentials stores token', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.clearSession();
    final user = await h.authRepository.login(
      email: h.memberEmail,
      password: h.memberPassword,
    );

    expect(user.email, h.memberEmail);
    expect(user.role, 'member');
    expect(user.memberId, isNotNull);

    final token = await h.storage.readToken();
    expect(token, isNotNull);
    expect(token!.isNotEmpty, isTrue);
  });

  test('invalid login surfaces server credential error', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.clearSession();
    await expectLater(
      h.authRepository.login(
        email: h.memberEmail,
        password: 'definitely-wrong-password',
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.message.toLowerCase(),
          'message',
          contains('credentials'),
        ),
      ),
    );
    expect(await h.storage.readToken(), isNull);
  });

  test('logout clears stored credentials', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsMember();
    expect(await h.storage.readToken(), isNotNull);

    await h.authRepository.logout();
    expect(await h.storage.readToken(), isNull);

    await expectLater(
      h.authApi.me(),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('authenticated member profile retrieval', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsMember();
    final profile = await h.memberApi.me();
    expect(profile.email, h.memberEmail);
    expect(profile.memberId, 'BYN-INT-0001');
    expect(profile.phone, isNotNull);
  });

  test('notice listing and notice details', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsMember();
    final notices = await h.noticeApi.list();
    expect(notices, isNotEmpty);

    final match = notices.firstWhere(
      (n) => n.title == 'Integration Notice',
      orElse: () => notices.first,
    );
    final detail = await h.noticeApi.show(match.id);
    expect(detail.id, match.id);
    expect(detail.body.toLowerCase(), contains('integration'));
  });

  test('notification listing and read/unread status', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsMember();
    final page = await h.notificationApi.list();
    expect(page.items, isNotEmpty);

    final unreadBefore = await h.notificationApi.unreadCount();
    expect(unreadBefore, greaterThan(0));

    final unreadItem = page.items.firstWhere((n) => !n.isRead);
    final marked = await h.notificationApi.markRead(unreadItem.id);
    expect(marked.isRead, isTrue);

    final unreadAfter = await h.notificationApi.unreadCount();
    expect(unreadAfter, lessThan(unreadBefore));
  });

  test('member contribution history and outstanding balance', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsMember();

    final balance = await h.financeApi.myBalance();
    expect(balance.outstanding, '300.00');
    expect(balance.totalDue, '500.00');
    expect(balance.totalAllocated, '200.00');

    final dues = await h.financeApi.myDues();
    expect(dues, isNotEmpty);
    expect(dues.first.amountDue, '500.00');
    expect(dues.first.outstanding, '300.00');

    final payments = await h.financeApi.myPayments();
    expect(payments, isNotEmpty);
    expect(payments.first.amount, '200.00');
    expect(payments.first.status, 'posted');
  });

  test('invalid token is rejected as unauthorized', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.storage.saveToken('invalid-token-value');
    await expectLater(
      h.authApi.me(),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('network errors surface as AppException', () async {
    if (!requireHarness()) {
      return;
    }

    final storage = SecureStorageService(memory: <String, String>{});
    final api = AuthApi(
      ApiClient(
        secureStorage: storage,
        dio: Dio(
          BaseOptions(
            baseUrl: 'http://127.0.0.1:1/api/v1',
            connectTimeout: const Duration(milliseconds: 400),
            receiveTimeout: const Duration(milliseconds: 400),
          ),
        ),
      ),
    );

    await expectLater(
      api.login(email: 'x@y.z', password: 'x'),
      throwsA(isA<AppException>()),
    );
  });

  test('server error endpoint returns mapped failure when enabled', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsMember();
    try {
      await h.client.get('/testing/server-error');
      fail('Expected server-error endpoint to throw');
    } on DioException catch (error) {
      final nested = error.error;
      expect(nested, isA<AppException>());
      expect((nested as AppException).statusCode, anyOf(500, 404));
    }
  });

  test('member cannot access another member private information', () async {
    if (!requireHarness()) {
      return;
    }
    final h = harness!;

    await h.loginAsOtherMember();
    final otherProfile = await h.memberApi.me();

    await h.clearSession();
    await h.loginAsMember();

    await expectLater(
      h.client.get('/members/${otherProfile.id}'),
      throwsA(
        isA<DioException>().having(
          (e) => (e.error as AppException?)?.statusCode,
          'status',
          403,
        ),
      ),
    );

    await expectLater(
      h.client.get('/balances/${otherProfile.id}'),
      throwsA(
        isA<DioException>().having(
          (e) => (e.error as AppException?)?.statusCode,
          'status',
          403,
        ),
      ),
    );
  });
}

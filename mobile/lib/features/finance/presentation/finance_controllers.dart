import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/finance_api.dart';
import '../domain/member_balance.dart';
import '../domain/member_due.dart';
import '../domain/member_payment.dart';

final financeApiProvider = Provider<FinanceApi>((ref) {
  return FinanceApi(ref.watch(apiClientProvider));
});

final financeBalanceProvider =
    AsyncNotifierProvider<FinanceBalanceNotifier, MemberBalance>(
  FinanceBalanceNotifier.new,
);

class FinanceBalanceNotifier extends AsyncNotifier<MemberBalance> {
  @override
  Future<MemberBalance> build() => ref.read(financeApiProvider).myBalance();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(financeApiProvider).myBalance(),
    );
  }
}

final financeDuesProvider =
    AsyncNotifierProvider<FinanceDuesNotifier, List<MemberDue>>(
  FinanceDuesNotifier.new,
);

class FinanceDuesNotifier extends AsyncNotifier<List<MemberDue>> {
  @override
  Future<List<MemberDue>> build() => ref.read(financeApiProvider).myDues();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(financeApiProvider).myDues(),
    );
  }
}

final financePaymentsProvider =
    AsyncNotifierProvider<FinancePaymentsNotifier, List<MemberPayment>>(
  FinancePaymentsNotifier.new,
);

class FinancePaymentsNotifier extends AsyncNotifier<List<MemberPayment>> {
  @override
  Future<List<MemberPayment>> build() =>
      ref.read(financeApiProvider).myPayments();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(financeApiProvider).myPayments(),
    );
  }
}

final financePaymentDetailProvider = FutureProvider.autoDispose
    .family<MemberPayment, int>((ref, id) {
  return ref.watch(financeApiProvider).paymentDetail(id);
});

final financeStatementProvider =
    AsyncNotifierProvider<FinanceStatementNotifier, MemberStatement>(
  FinanceStatementNotifier.new,
);

class FinanceStatementNotifier extends AsyncNotifier<MemberStatement> {
  String? _from;
  String? _to;

  @override
  Future<MemberStatement> build() {
    return ref.read(financeApiProvider).myStatement(from: _from, to: _to);
  }

  Future<void> applyFilters({String? from, String? to}) async {
    _from = from;
    _to = to;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(financeApiProvider).myStatement(from: _from, to: _to),
    );
  }

  Future<void> refresh() => applyFilters(from: _from, to: _to);
}

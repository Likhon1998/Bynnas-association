import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../members/domain/member.dart';
import '../data/staff_api.dart';

final staffApiProvider = Provider<StaffApi>((ref) {
  return StaffApi(ref.watch(apiClientProvider));
});

final staffDashboardProvider =
    AsyncNotifierProvider<StaffDashboardNotifier, Map<String, dynamic>>(
  StaffDashboardNotifier.new,
);

class StaffDashboardNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() =>
      ref.read(staffApiProvider).dashboard();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(staffApiProvider).dashboard());
  }
}

final staffMembersProvider =
    AsyncNotifierProvider<StaffMembersNotifier, List<Member>>(
  StaffMembersNotifier.new,
);

class StaffMembersNotifier extends AsyncNotifier<List<Member>> {
  String? _search;

  @override
  Future<List<Member>> build() =>
      ref.read(staffApiProvider).listMembers(search: _search);

  Future<void> search(String? query) async {
    _search = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(staffApiProvider).listMembers(search: _search),
    );
  }

  Future<void> refresh() => search(_search);
}

final staffPaymentsProvider =
    AsyncNotifierProvider<StaffPaymentsNotifier, List<Map<String, dynamic>>>(
  StaffPaymentsNotifier.new,
);

class StaffPaymentsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() =>
      ref.read(staffApiProvider).listPayments();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(staffApiProvider).listPayments());
  }
}

final staffMemberWiseReportProvider =
    AsyncNotifierProvider<StaffMemberWiseReportNotifier, Map<String, dynamic>>(
  StaffMemberWiseReportNotifier.new,
);

class StaffMemberWiseReportNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() =>
      ref.read(staffApiProvider).memberWiseReport();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(staffApiProvider).memberWiseReport(),
    );
  }
}

final staffMonthWiseReportProvider =
    AsyncNotifierProvider<StaffMonthWiseReportNotifier, Map<String, dynamic>>(
  StaffMonthWiseReportNotifier.new,
);

class StaffMonthWiseReportNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() =>
      ref.read(staffApiProvider).monthWiseReport();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(staffApiProvider).monthWiseReport(),
    );
  }
}

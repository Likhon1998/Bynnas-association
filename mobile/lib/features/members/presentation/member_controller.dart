import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/member_api.dart';
import '../domain/member.dart';

final memberApiProvider = Provider<MemberApi>((ref) {
  return MemberApi(ref.watch(apiClientProvider));
});

final myMemberProvider =
    AsyncNotifierProvider<MyMemberController, Member?>(MyMemberController.new);

class MyMemberController extends AsyncNotifier<Member?> {
  MemberApi get _api => ref.read(memberApiProvider);

  @override
  Future<Member?> build() async {
    return _api.me();
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_api.me);
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _api.updateMe(name: name, phone: phone, address: address),
    );
  }
}

import 'package:bynnas_association/features/auth/domain/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuthUser parses API payload', () {
    final user = AuthUser.fromJson({
      'id': 7,
      'name': 'Asha Member',
      'email': 'asha@example.com',
      'role': 'member',
      'member_id': 'BYN-2026-0007',
      'is_active': true,
    });

    expect(user.id, 7);
    expect(user.memberId, 'BYN-2026-0007');
    expect(user.role, 'member');
    expect(user.isActive, isTrue);
  });
}

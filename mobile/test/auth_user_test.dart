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
    expect(user.isMember, isTrue);
    expect(user.isStaff, isFalse);
  });

  test('AuthUser recognizes staff roles', () {
    final admin = AuthUser.fromJson({
      'id': 1,
      'name': 'Admin',
      'email': 'admin@example.com',
      'role': 'admin',
      'is_active': true,
    });
    expect(admin.isStaff, isTrue);
    expect(admin.isMember, isFalse);
  });
}

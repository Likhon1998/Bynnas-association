class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.memberId,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? memberId;
  final bool isActive;

  bool get isMember => role == 'member';

  bool get isStaff =>
      role == 'admin' || role == 'super_admin' || role == 'accountant';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'member',
      memberId: json['member_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'member_id': memberId,
      'is_active': isActive,
    };
  }
}

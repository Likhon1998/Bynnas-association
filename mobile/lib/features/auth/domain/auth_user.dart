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

  bool get isSuperAdmin => role == 'super_admin';

  bool get isAdmin => role == 'admin' || role == 'super_admin';

  bool get isAccountant => role == 'accountant';

  /// Add / edit / deactivate members, compose notices, SMS.
  bool get canManageMembers => isAdmin;

  bool get canManageNotices => isAdmin;

  bool get canSendSms => isAdmin;

  bool get canManageStaff => isSuperAdmin;

  bool get canRunBackups => isSuperAdmin;

  bool get canApproveFinance => isAdmin;

  bool get canRecordPayments => isStaff;

  bool get canViewReports => isStaff;

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

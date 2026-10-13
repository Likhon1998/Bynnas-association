class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.memberId,
    required this.isActive,
    this.phone,
    this.address,
    this.joinedOn,
    this.notes,
  });

  final int id;
  final String name;
  final String email;
  final String? memberId;
  final bool isActive;
  final String? phone;
  final String? address;
  final String? joinedOn;
  final String? notes;

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      memberId: json['member_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      joinedOn: json['joined_on'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

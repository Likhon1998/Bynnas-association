class MemberBalance {
  const MemberBalance({
    required this.userId,
    required this.currency,
    required this.totalDue,
    required this.totalAllocated,
    required this.outstanding,
    required this.duesCount,
  });

  final int userId;
  final String currency;
  final String totalDue;
  final String totalAllocated;
  final String outstanding;
  final int duesCount;

  factory MemberBalance.fromJson(Map<String, dynamic> json) {
    return MemberBalance(
      userId: (json['user_id'] as num).toInt(),
      currency: json['currency'] as String? ?? 'BDT',
      totalDue: json['total_due']?.toString() ?? '0.00',
      totalAllocated: json['total_allocated']?.toString() ?? '0.00',
      outstanding: json['outstanding']?.toString() ?? '0.00',
      duesCount: (json['dues_count'] as num?)?.toInt() ?? 0,
    );
  }
}

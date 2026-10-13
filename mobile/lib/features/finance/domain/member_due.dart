class MemberDue {
  const MemberDue({
    required this.id,
    required this.amountDue,
    required this.amountAllocated,
    required this.outstanding,
    required this.status,
    this.periodLabel,
    this.currency = 'BDT',
  });

  final int id;
  final String amountDue;
  final String amountAllocated;
  final String outstanding;
  final String status;
  final String? periodLabel;
  final String currency;

  factory MemberDue.fromJson(Map<String, dynamic> json) {
    final period = json['period'];
    return MemberDue(
      id: (json['id'] as num).toInt(),
      amountDue: json['amount_due']?.toString() ?? '0.00',
      amountAllocated: json['amount_allocated']?.toString() ?? '0.00',
      outstanding: json['outstanding']?.toString() ?? '0.00',
      status: json['status'] as String? ?? '',
      periodLabel: period is Map<String, dynamic>
          ? period['label'] as String?
          : null,
      currency: json['currency'] as String? ?? 'BDT',
    );
  }
}

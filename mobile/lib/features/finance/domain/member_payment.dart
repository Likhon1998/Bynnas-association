class MemberPayment {
  const MemberPayment({
    required this.id,
    required this.amount,
    required this.status,
    required this.receiptNumber,
    this.method,
    this.receivedAt,
    this.reversalReason,
    this.recordedByName,
    this.allocations = const [],
    this.currency = 'BDT',
  });

  final int id;
  final String amount;
  final String status;
  final String receiptNumber;
  final String? method;
  final String? receivedAt;
  final String? reversalReason;
  final String? recordedByName;
  final List<PaymentAllocationLine> allocations;
  final String currency;

  bool get isReversed => status == 'reversed';

  factory MemberPayment.fromJson(Map<String, dynamic> json) {
    final allocationsRaw = json['allocations'];
    final recorded = json['recorded_by_user'];
    return MemberPayment(
      id: (json['id'] as num).toInt(),
      amount: json['amount']?.toString() ?? '0.00',
      status: json['status'] as String? ?? '',
      receiptNumber: json['receipt_number'] as String? ?? '',
      method: json['method'] as String?,
      receivedAt: json['received_at'] as String?,
      reversalReason: json['reversal_reason'] as String?,
      recordedByName: recorded is Map
          ? recorded['name']?.toString()
          : null,
      currency: json['currency'] as String? ?? 'BDT',
      allocations: allocationsRaw is List
          ? allocationsRaw
              .whereType<Map<String, dynamic>>()
              .map(PaymentAllocationLine.fromJson)
              .toList()
          : const [],
    );
  }
}

class PaymentAllocationLine {
  const PaymentAllocationLine({
    required this.amount,
    required this.isReversed,
    this.periodLabel,
  });

  final String amount;
  final bool isReversed;
  final String? periodLabel;

  factory PaymentAllocationLine.fromJson(Map<String, dynamic> json) {
    final due = json['member_due'];
    String? periodLabel;
    if (due is Map<String, dynamic>) {
      final period = due['period'];
      if (period is Map<String, dynamic>) {
        periodLabel = period['label'] as String?;
      }
    }
    return PaymentAllocationLine(
      amount: json['amount']?.toString() ?? '0.00',
      isReversed: json['is_reversed'] == true,
      periodLabel: periodLabel,
    );
  }
}

class MemberStatement {
  const MemberStatement({
    required this.expectedDues,
    required this.totalPaid,
    required this.allocatedToDues,
    required this.outstanding,
    required this.dues,
    required this.payments,
    this.currency = 'BDT',
  });

  final String expectedDues;
  final String totalPaid;
  final String allocatedToDues;
  final String outstanding;
  final String currency;
  final List<Map<String, dynamic>> dues;
  final List<Map<String, dynamic>> payments;

  factory MemberStatement.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return MemberStatement(
      expectedDues: summary['expected_dues']?.toString() ?? '0.00',
      totalPaid: summary['total_paid']?.toString() ?? '0.00',
      allocatedToDues: summary['allocated_to_dues']?.toString() ?? '0.00',
      outstanding: summary['outstanding']?.toString() ?? '0.00',
      currency: summary['currency'] as String? ?? 'BDT',
      dues: (json['dues'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
          const [],
      payments:
          (json['payments'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
              const [],
    );
  }
}

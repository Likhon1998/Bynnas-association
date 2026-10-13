import 'package:bynnas_association/features/finance/domain/member_balance.dart';
import 'package:bynnas_association/features/finance/domain/member_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemberBalance parses API money fields as strings', () {
    final balance = MemberBalance.fromJson({
      'user_id': 1,
      'currency': 'BDT',
      'total_due': '500.00',
      'total_allocated': '200.00',
      'outstanding': '300.00',
      'dues_count': 1,
    });

    expect(balance.outstanding, '300.00');
    expect(balance.totalDue, '500.00');
  });

  test('MemberPayment marks reversed receipts clearly', () {
    final payment = MemberPayment.fromJson({
      'id': 9,
      'amount': '40.00',
      'status': 'reversed',
      'receipt_number': 'RCPT-20260410-000001',
      'reversal_reason': 'Correction',
      'allocations': [
        {
          'amount': '40.00',
          'is_reversed': true,
          'member_due': {
            'period': {'label': '2026-04'},
          },
        },
      ],
    });

    expect(payment.isReversed, isTrue);
    expect(payment.allocations.first.periodLabel, '2026-04');
    expect(payment.reversalReason, 'Correction');
  });

  test('MemberStatement uses server summary totals', () {
    final statement = MemberStatement.fromJson({
      'summary': {
        'expected_dues': '200.00',
        'total_paid': '50.00',
        'allocated_to_dues': '50.00',
        'outstanding': '150.00',
        'currency': 'BDT',
      },
      'dues': [
        {
          'period_label': '2026-06',
          'amount_due': '200.00',
          'outstanding': '150.00',
          'status': 'partial',
        },
      ],
      'payments': [],
    });

    expect(statement.expectedDues, '200.00');
    expect(statement.outstanding, '150.00');
    expect(statement.dues, isNotEmpty);
  });
}

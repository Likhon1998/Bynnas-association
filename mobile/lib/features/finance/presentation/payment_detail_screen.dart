import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../staff/presentation/staff_controllers.dart';
import 'finance_controllers.dart';

class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({super.key, required this.paymentId});

  final int paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(financePaymentDetailProvider(paymentId));
    final user = ref.watch(authControllerProvider).asData?.value;
    final isStaff = user?.isStaff ?? false;

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.navy,
                    ),
                    Expanded(
                      child: Text(
                        'Receipt detail',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: detail.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error.toString()),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            financePaymentDetailProvider(paymentId),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (payment) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      if (payment.isReversed)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'REVERSED — not a valid active payment.\n${payment.reversalReason ?? ''}',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF9F1239),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      _line('Receipt', payment.receiptNumber),
                      _line(
                        'Amount',
                        '৳ ${payment.amount} ${payment.currency}',
                      ),
                      _line('Status', payment.status),
                      _line('Method', payment.method ?? '—'),
                      _line('Date', payment.receivedAt ?? '—'),
                      const SizedBox(height: 16),
                      Text(
                        'Allocations',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (payment.allocations.isEmpty)
                        Text(
                          'No period allocations.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                          ),
                        )
                      else
                        ...payment.allocations.map(
                          (line) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.periodLabel ?? 'Period'),
                            trailing: Text('৳ ${line.amount}'),
                            subtitle: Text(
                              line.isReversed ? 'Reversed' : 'Active',
                            ),
                          ),
                        ),
                      if (isStaff && !payment.isReversed) ...[
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => _confirmReverse(context, ref),
                          child: const Text('Reverse payment'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReverse(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reverse payment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Required — history is preserved',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reverse'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) {
      return;
    }
    try {
      await ref.read(staffApiProvider).reversePayment(
            paymentId: paymentId,
            reason: reason,
          );
      ref.invalidate(financePaymentDetailProvider(paymentId));
      ref.invalidate(staffPaymentsProvider);
      ref.invalidate(staffDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment reversed')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException ? error.message : error.toString(),
            ),
          ),
        );
      }
    }
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

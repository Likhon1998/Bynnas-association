import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import 'finance_controllers.dart';

class PaymentsListScreen extends ConsumerWidget {
  const PaymentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(financePaymentsProvider);

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
                        'Payment history',
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
                child: payments.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load payments', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () => ref.read(financePaymentsProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No payments yet',
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => ref.read(financePaymentsProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final payment = items[index];
                          return Material(
                            color: payment.isReversed
                                ? const Color(0xFFFFF1F2)
                                : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push('/finance/payments/${payment.id}'),
                              child: ListTile(
                                title: Text(
                                  payment.receiptNumber,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                subtitle: Text(
                                  payment.isReversed
                                      ? 'REVERSED · ${payment.receivedAt ?? ''}'
                                      : (payment.receivedAt ?? ''),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: payment.isReversed
                                        ? const Color(0xFF9F1239)
                                        : AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Text(
                                  '৳ ${payment.amount}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

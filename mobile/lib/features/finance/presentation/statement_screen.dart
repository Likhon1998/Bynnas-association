import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import 'finance_controllers.dart';

class StatementScreen extends ConsumerWidget {
  const StatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statement = ref.watch(financeStatementProvider);

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
                        'Member statement',
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
                child: statement.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(error.toString()),
                        TextButton(
                          onPressed: () =>
                              ref.read(financeStatementProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => RefreshIndicator(
                    onRefresh: () =>
                        ref.read(financeStatementProvider.notifier).refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        _card('Expected', '৳ ${data.expectedDues}'),
                        _card('Paid', '৳ ${data.totalPaid}'),
                        _card('Outstanding', '৳ ${data.outstanding}'),
                        const SizedBox(height: 16),
                        Text(
                          'Monthly status',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (data.dues.isEmpty)
                          Text(
                            'No dues in this period.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                            ),
                          )
                        else
                          ...data.dues.map(
                            (due) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${due['period_label'] ?? 'Period'}'),
                              subtitle: Text(
                                'Due ${due['amount_due']} · Out ${due['outstanding']}',
                              ),
                              trailing: Text('${due['status']}'.toUpperCase()),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Payments',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (data.payments.isEmpty)
                          Text(
                            'No payments in this period.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                            ),
                          )
                        else
                          ...data.payments.map(
                            (payment) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${payment['receipt_number']}'),
                              subtitle: Text('${payment['received_at'] ?? ''}'),
                              trailing: Text('৳ ${payment['amount']}'),
                              onTap: () {
                                final id = payment['id'];
                                if (id is int) {
                                  context.push('/finance/payments/$id');
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

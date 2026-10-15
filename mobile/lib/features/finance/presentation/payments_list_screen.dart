import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
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
              ScreenHeader(
                title: 'Payment history',
                subtitle: 'Your posted receipts',
                leading: const ScreenBackButton(),
              ),
              Expanded(
                child: AsyncBody(
                  value: payments,
                  onRetry: () =>
                      ref.read(financePaymentsProvider.notifier).refresh(),
                  emptyTitle: 'No payments yet',
                  emptyDetail:
                      'Receipts will appear after payments are posted.',
                  isEmpty: (items) => items.isEmpty,
                  data: (items) => RefreshIndicator(
                    color: AppColors.magenta,
                    onRefresh: () =>
                        ref.read(financePaymentsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final payment = items[index];
                        final reversed = payment.isReversed;
                        return FadeRise(
                          delay: Duration(
                            milliseconds: 30 + (index.clamp(0, 8) * 30),
                          ),
                          child: SectionCard(
                            onTap: () => context
                                .push('/finance/payments/${payment.id}'),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: reversed
                                        ? AppColors.danger
                                            .withValues(alpha: 0.1)
                                        : AppColors.magenta
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    reversed
                                        ? Icons.undo_rounded
                                        : Icons.receipt_long_rounded,
                                    color: reversed
                                        ? AppColors.danger
                                        : AppColors.magenta,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        payment.receiptNumber,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.navy,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        [
                                          AppFormat.dateTime(payment.receivedAt),
                                          if (payment.method != null)
                                            AppFormat.statusLabel(
                                              payment.method,
                                            ),
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      AppFormat.money(payment.amount),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        color: reversed
                                            ? AppColors.textMuted
                                            : AppColors.navy,
                                        fontSize: 14.5,
                                        decoration: reversed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    StatusChip(payment.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}

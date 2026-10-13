import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'staff_controllers.dart';

class StaffPaymentsScreen extends ConsumerWidget {
  const StaffPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(staffPaymentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/payments/record'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        label: const Text('Record'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Payments',
                subtitle: 'Receipts posted by the association',
                leading: context.canPop()
                    ? const ScreenBackButton()
                    : const SizedBox(width: 8),
              ),
              Expanded(
                child: AsyncBody(
                  value: payments,
                  onRetry: () =>
                      ref.read(staffPaymentsProvider.notifier).refresh(),
                  emptyTitle: 'No payments yet',
                  emptyDetail: 'Record a payment to see receipts here.',
                  isEmpty: (items) => items.isEmpty,
                  data: (items) => RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () =>
                        ref.read(staffPaymentsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final payment = items[index];
                        final id = (payment['id'] as num?)?.toInt() ?? 0;
                        final status = '${payment['status'] ?? ''}';
                        final user = payment['user'];
                        final memberName = user is Map
                            ? '${user['name'] ?? 'Member'}'
                            : 'Member';

                        return SectionCard(
                          onTap: () => context.push('/finance/payments/$id'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${payment['receipt_number'] ?? 'Receipt'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$memberName · ${payment['received_at'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
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
                                    AppFormat.money(payment['amount']),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusChip(status),
                                ],
                              ),
                            ],
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

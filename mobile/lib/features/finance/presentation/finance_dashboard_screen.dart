import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'finance_controllers.dart';

class FinanceDashboardScreen extends ConsumerWidget {
  const FinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(financeBalanceProvider);
    final dues = ref.watch(financeDuesProvider);

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'My finances',
                subtitle: 'Balances, dues, and payment history',
                leading: context.canPop()
                    ? const ScreenBackButton()
                    : const SizedBox(width: 8),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async {
                    await ref.read(financeBalanceProvider.notifier).refresh();
                    await ref.read(financeDuesProvider.notifier).refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      balance.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        error: (error, _) => _FinanceMessage(
                          title: 'Could not load balance',
                          detail: AppFormat.friendlyError(error),
                          onRetry: () => ref
                              .read(financeBalanceProvider.notifier)
                              .refresh(),
                        ),
                        data: (data) => Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: MetricTile(
                                    label: 'Outstanding',
                                    value: AppFormat.money(data.outstanding),
                                    emphasis: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: MetricTile(
                                    label: 'Total paid',
                                    value:
                                        AppFormat.money(data.totalAllocated),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            MetricTile(
                              label: 'Expected contributions',
                              value: AppFormat.money(data.totalDue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _NavTile(
                              label: 'Payments',
                              icon: Icons.receipt_long_outlined,
                              onTap: () => context.push('/finance/payments'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _NavTile(
                              label: 'Statement',
                              icon: Icons.description_outlined,
                              onTap: () => context.push('/finance/statement'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Monthly contribution status',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      dues.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        error: (error, _) => _FinanceMessage(
                          title: 'Could not load dues',
                          detail: AppFormat.friendlyError(error),
                          onRetry: () =>
                              ref.read(financeDuesProvider.notifier).refresh(),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return _FinanceMessage(
                              title: 'No dues yet',
                              detail:
                                  'Monthly contribution lines will appear here.',
                              onRetry: () => ref
                                  .read(financeDuesProvider.notifier)
                                  .refresh(),
                            );
                          }
                          return Column(
                            children: items
                                .map(
                                  (due) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: SectionCard(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  due.periodLabel ?? 'Period',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.navy,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Due ${AppFormat.money(due.amountDue)} · Out ${AppFormat.money(due.outstanding)}',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: AppColors.textMuted,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusChip(due.status),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
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
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceMessage extends StatelessWidget {
  const _FinanceMessage({
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

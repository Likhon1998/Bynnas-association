import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
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
                  color: AppColors.magenta,
                  onRefresh: () async {
                    await ref.read(financeBalanceProvider.notifier).refresh();
                    await ref.read(financeDuesProvider.notifier).refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    children: [
                      balance.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.magenta,
                            ),
                          ),
                        ),
                        error: (error, _) => AppEmptyCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load balance',
                          detail: AppFormat.friendlyError(error),
                        ),
                        data: (data) => FadeRise(
                          child: SectionCard(
                            padding:
                                const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Outstanding',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppFormat.money(data.outstanding),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.magenta,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                    letterSpacing: -0.8,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  height: 1,
                                  color: AppColors.fieldBorder
                                      .withValues(alpha: 0.85),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _Stat(
                                        label: 'Paid',
                                        value: AppFormat.money(
                                          data.totalAllocated,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _Stat(
                                        label: 'Expected',
                                        value: AppFormat.money(data.totalDue),
                                        alignEnd: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeRise(
                        delay: const Duration(milliseconds: 50),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppActionTile(
                                icon: Icons.receipt_long_rounded,
                                title: 'Payments',
                                subtitle: 'Receipt history',
                                tint: AppColors.magenta,
                                onTap: () =>
                                    context.push('/finance/payments'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeRise(
                        delay: const Duration(milliseconds: 80),
                        child: AppActionTile(
                          icon: Icons.description_rounded,
                          title: 'Statement',
                          subtitle: 'Period summary',
                          tint: AppColors.navy,
                          onTap: () => context.push('/finance/statement'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeRise(
                        delay: const Duration(milliseconds: 100),
                        child: const SectionLabel('Monthly dues'),
                      ),
                      const SizedBox(height: 10),
                      dues.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.magenta,
                            ),
                          ),
                        ),
                        error: (error, _) => AppEmptyCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load dues',
                          detail: AppFormat.friendlyError(error),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return const AppEmptyCard(
                              icon: Icons.calendar_month_outlined,
                              title: 'No dues yet',
                              detail:
                                  'Monthly contribution lines will appear here.',
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                FadeRise(
                                  delay: Duration(
                                    milliseconds:
                                        110 + (i.clamp(0, 8) * 28),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: SectionCard(
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        12,
                                        12,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  items[i].periodLabel ??
                                                      'Period',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.navy,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'Due ${AppFormat.money(items[i].amountDue)} · Out ${AppFormat.money(items[i].outstanding)}',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: AppColors.textMuted,
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          StatusChip(items[i].status),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

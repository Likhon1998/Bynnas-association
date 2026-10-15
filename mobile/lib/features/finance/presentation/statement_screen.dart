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
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: ScreenHeader(
                  title: 'Statement',
                  subtitle: 'Your contribution summary for this period',
                  leading: ScreenBackButton(),
                ),
              ),
              Expanded(
                child: statement.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.magenta),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(18),
                    child: AppEmptyCard(
                      icon: Icons.error_outline_rounded,
                      title: 'Could not load statement',
                      detail: AppFormat.friendlyError(error),
                    ),
                  ),
                  data: (data) => RefreshIndicator(
                    color: AppColors.magenta,
                    onRefresh: () =>
                        ref.read(financeStatementProvider.notifier).refresh(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      children: [
                        FadeRise(
                          child: SectionCard(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              children: [
                                _SummaryRow(
                                  label: 'Expected',
                                  value: AppFormat.money(data.expectedDues),
                                ),
                                const SizedBox(height: 10),
                                _SummaryRow(
                                  label: 'Paid',
                                  value: AppFormat.money(data.totalPaid),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  height: 1,
                                  color: AppColors.fieldBorder
                                      .withValues(alpha: 0.85),
                                ),
                                const SizedBox(height: 10),
                                _SummaryRow(
                                  label: 'Outstanding',
                                  value: AppFormat.money(data.outstanding),
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeRise(
                          delay: const Duration(milliseconds: 50),
                          child: const SectionLabel('Monthly status'),
                        ),
                        const SizedBox(height: 10),
                        if (data.dues.isEmpty)
                          const AppEmptyCard(
                            icon: Icons.calendar_month_outlined,
                            title: 'No dues in this period',
                          )
                        else
                          ...data.dues.asMap().entries.map((entry) {
                            final i = entry.key;
                            final due = entry.value;
                            return FadeRise(
                              delay: Duration(
                                milliseconds: 70 + (i.clamp(0, 8) * 25),
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
                                              '${due['period_label'] ?? 'Period'}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.navy,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Due ${AppFormat.money(due['amount_due'])} · Out ${AppFormat.money(due['outstanding'])}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: AppColors.textMuted,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusChip('${due['status']}'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 14),
                        FadeRise(
                          delay: const Duration(milliseconds: 90),
                          child: const SectionLabel('Payments'),
                        ),
                        const SizedBox(height: 10),
                        if (data.payments.isEmpty)
                          const AppEmptyCard(
                            icon: Icons.receipt_long_outlined,
                            title: 'No payments in this period',
                          )
                        else
                          ...data.payments.asMap().entries.map((entry) {
                            final i = entry.key;
                            final payment = entry.value;
                            return FadeRise(
                              delay: Duration(
                                milliseconds: 100 + (i.clamp(0, 8) * 25),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: SectionCard(
                                  onTap: () {
                                    final id = payment['id'];
                                    if (id is num) {
                                      context.push(
                                        '/finance/payments/${id.toInt()}',
                                      );
                                    }
                                  },
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
                                              '${payment['receipt_number']}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.navy,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              AppFormat.dateTime(
                                                payment['received_at'],
                                              ),
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppFormat.money(payment['amount']),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.magenta,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: emphasize ? AppColors.magenta : AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 18 : 15,
          ),
        ),
      ],
    );
  }
}

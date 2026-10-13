import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import 'staff_controllers.dart';

class StaffReportsScreen extends ConsumerWidget {
  const StaffReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberWise = ref.watch(staffMemberWiseReportProvider);
    final monthWise = ref.watch(staffMonthWiseReportProvider);

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              await ref.read(staffMemberWiseReportProvider.notifier).refresh();
              await ref.read(staffMonthWiseReportProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                ScreenHeader(
                  title: 'Reports',
                  subtitle: 'Server-side collection totals',
                  leading: context.canPop()
                      ? const ScreenBackButton()
                      : const SizedBox(width: 8),
                ),
                const SizedBox(height: 8),
                Text(
                  'Member-wise',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                memberWise.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                  error: (error, _) => Text(AppFormat.friendlyError(error)),
                  data: (payload) {
                    final summary =
                        payload['summary'] as Map<String, dynamic>? ?? {};
                    final rows = (payload['data'] as List?)
                            ?.whereType<Map<String, dynamic>>()
                            .toList() ??
                        const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionCard(
                          child: Text(
                            'Expected ${AppFormat.money(summary['expected_dues'])} · Collected ${AppFormat.money(summary['actual_collections'])} · Outstanding ${AppFormat.money(summary['outstanding'])}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...rows.take(20).map(
                              (row) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
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
                                              '${row['name']}',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                            Text(
                                              '${row['member_id'] ?? '—'}',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppFormat.money(row['outstanding']),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Text(
                  'Month-wise',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                monthWise.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                  error: (error, _) => Text(AppFormat.friendlyError(error)),
                  data: (payload) {
                    final rows = (payload['data'] as List?)
                            ?.whereType<Map<String, dynamic>>()
                            .toList() ??
                        const [];
                    if (rows.isEmpty) {
                      return Text(
                        'No periods yet',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                        ),
                      );
                    }
                    return Column(
                      children: rows
                          .map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SectionCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${row['label']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Expected ${AppFormat.money(row['expected_dues'])} · Collected ${AppFormat.money(row['actual_collections'])}',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
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
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import 'staff_controllers.dart';

class StaffReportsScreen extends ConsumerStatefulWidget {
  const StaffReportsScreen({super.key});

  @override
  ConsumerState<StaffReportsScreen> createState() => _StaffReportsScreenState();
}

class _StaffReportsScreenState extends ConsumerState<StaffReportsScreen> {
  var _tab = 0; // 0 member, 1 month
  var _downloading = false;

  Future<void> _downloadPdf({required bool memberWise}) async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(staffApiProvider)
          .downloadReportPdf(memberWise: memberWise);
      final name = memberWise
          ? 'member-wise-report.pdf'
          : 'month-wise-report.pdf';
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'application/pdf',
        name: name,
      );
      await SharePlus.instance.share(
        ShareParams(files: [file], text: name),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name ready to save/share'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppFormat.friendlyError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberWise = ref.watch(staffMemberWiseReportProvider);
    final monthWise = ref.watch(staffMonthWiseReportProvider);

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () async {
              await ref.read(staffMemberWiseReportProvider.notifier).refresh();
              await ref.read(staffMonthWiseReportProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                ScreenHeader(
                  title: 'Reports',
                  subtitle: 'Collection totals from the server',
                  leading: context.canPop()
                      ? const ScreenBackButton()
                      : const SizedBox(width: 8),
                ),
                FadeRise(
                  child: SectionCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppFilterChip(
                            label: 'Members',
                            selected: _tab == 0,
                            expanded: true,
                            onTap: () => setState(() => _tab = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppFilterChip(
                            label: 'Months',
                            selected: _tab == 1,
                            expanded: true,
                            onTap: () => setState(() => _tab = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeRise(
                  delay: const Duration(milliseconds: 50),
                  child: AppActionTile(
                    icon: Icons.picture_as_pdf_rounded,
                    title: _tab == 0
                        ? 'Download member PDF'
                        : 'Download month PDF',
                    subtitle: _downloading
                        ? 'Preparing file…'
                        : 'Share or save the report',
                    tint: AppColors.magenta,
                    onTap: _downloading
                        ? () {}
                        : () => _downloadPdf(memberWise: _tab == 0),
                    trailing: _downloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                if (_tab == 0)
                  _MemberWiseBody(value: memberWise)
                else
                  _MonthWiseBody(value: monthWise),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberWiseBody extends StatelessWidget {
  const _MemberWiseBody({required this.value});

  final AsyncValue<Map<String, dynamic>> value;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.magenta),
        ),
      ),
      error: (error, _) => AppEmptyCard(
        icon: Icons.error_outline_rounded,
        title: 'Could not load report',
        detail: AppFormat.friendlyError(error),
      ),
      data: (payload) {
        final summary = payload['summary'] as Map<String, dynamic>? ?? {};
        final rows = (payload['data'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeRise(
              child: SectionCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Expected',
                        value: AppFormat.money(summary['expected_dues']),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Collected',
                        value: AppFormat.money(summary['actual_collections']),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: 'Outstanding',
                        value: AppFormat.money(summary['outstanding']),
                        emphasize: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Members'),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              const AppEmptyCard(
                icon: Icons.assessment_outlined,
                title: 'No member totals yet',
              )
            else
              ...rows.take(40).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return FadeRise(
                  delay: Duration(milliseconds: 60 + (i.clamp(0, 8) * 25)),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: SectionCard(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${row['name']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
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
        );
      },
    );
  }
}

class _MonthWiseBody extends StatelessWidget {
  const _MonthWiseBody({required this.value});

  final AsyncValue<Map<String, dynamic>> value;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.magenta),
        ),
      ),
      error: (error, _) => AppEmptyCard(
        icon: Icons.error_outline_rounded,
        title: 'Could not load report',
        detail: AppFormat.friendlyError(error),
      ),
      data: (payload) {
        final rows = (payload['data'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [];
        if (rows.isEmpty) {
          return const AppEmptyCard(
            icon: Icons.calendar_month_outlined,
            title: 'No periods yet',
            detail: 'Generate dues to start seeing month-wise totals.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Periods'),
            const SizedBox(height: 10),
            ...rows.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return FadeRise(
                delay: Duration(milliseconds: 60 + (i.clamp(0, 8) * 25)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: SectionCard(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['label']}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Expected',
                                value:
                                    AppFormat.money(row['expected_dues']),
                              ),
                            ),
                            Expanded(
                              child: _MiniStat(
                                label: 'Collected',
                                value: AppFormat.money(
                                  row['actual_collections'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: emphasize ? AppColors.magenta : AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

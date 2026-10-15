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
import 'staff_controllers.dart';

class StaffMonthStatusScreen extends ConsumerStatefulWidget {
  const StaffMonthStatusScreen({super.key});

  @override
  ConsumerState<StaffMonthStatusScreen> createState() =>
      _StaffMonthStatusScreenState();
}

class _StaffMonthStatusScreenState
    extends ConsumerState<StaffMonthStatusScreen> {
  late Future<Map<String, dynamic>> _future;
  String _filter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ref.read(staffApiProvider).currentMonthStatus();
  }

  void _reload() {
    setState(() {
      _future = ref.read(staffApiProvider).currentMonthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: ScreenHeader(
                  title: 'This month',
                  subtitle: 'Paid vs unpaid members for the current period',
                  leading: ScreenBackButton(),
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.magenta,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(18),
                        child: AppEmptyCard(
                          icon: Icons.error_outline_rounded,
                          title: 'Could not load status',
                          detail: AppFormat.friendlyError(snapshot.error!),
                        ),
                      );
                    }
                    final data = snapshot.data ?? {};
                    final period =
                        data['period'] as Map<String, dynamic>? ?? {};
                    final summary =
                        data['summary'] as Map<String, dynamic>? ?? {};
                    final rows = (data['rows'] as List?)
                            ?.whereType<Map<String, dynamic>>()
                            .toList() ??
                        const [];
                    final filtered = rows.where((row) {
                      if (_filter != 'all' &&
                          row['status']?.toString() != _filter) {
                        return false;
                      }
                      if (_query.trim().isEmpty) {
                        return true;
                      }
                      final q = _query.trim().toLowerCase();
                      final name = '${row['name'] ?? ''}'.toLowerCase();
                      final mid = '${row['member_id'] ?? ''}'.toLowerCase();
                      return name.contains(q) || mid.contains(q);
                    }).toList();

                    return RefreshIndicator(
                      color: AppColors.magenta,
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                        children: [
                          FadeRise(
                            child: SectionCard(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${period['label'] ?? 'Current period'}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: MetricTile(
                                          label: 'Paid',
                                          value: '${summary['paid'] ?? 0}',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: MetricTile(
                                          label: 'Unpaid',
                                          value: '${summary['unpaid'] ?? 0}',
                                          emphasis: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: MetricTile(
                                          label: 'Partial',
                                          value: '${summary['partial'] ?? 0}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeRise(
                            delay: const Duration(milliseconds: 50),
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search member…',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FadeRise(
                            delay: const Duration(milliseconds: 80),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final item in [
                                    ('all', 'All'),
                                    ('paid', 'Paid'),
                                    ('unpaid', 'Unpaid'),
                                    ('partial', 'Partial'),
                                  ]) ...[
                                    AppFilterChip(
                                      label: item.$2,
                                      selected: _filter == item.$1,
                                      onTap: () =>
                                          setState(() => _filter = item.$1),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (filtered.isEmpty)
                            const AppEmptyCard(
                              icon: Icons.fact_check_outlined,
                              title: 'No members match',
                              detail: 'Try another filter or search term.',
                            )
                          else
                            ...filtered.asMap().entries.map((entry) {
                              final index = entry.key;
                              final row = entry.value;
                              final id = (row['user_id'] as num?)?.toInt();
                              return FadeRise(
                                delay: Duration(
                                  milliseconds:
                                      100 + (index.clamp(0, 8) * 28),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: SectionCard(
                                    onTap: id == null
                                        ? null
                                        : () => context
                                            .push('/staff/members/$id'),
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      12,
                                      12,
                                      12,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            gradient: AppColors.brandDiagonal,
                                            borderRadius:
                                                BorderRadius.circular(13),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${row['name']}'.isNotEmpty
                                                ? '${row['name']}'[0]
                                                    .toUpperCase()
                                                : '?',
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${row['name']}',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14,
                                                  color: AppColors.navy,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${row['member_id'] ?? '—'} · Out ${AppFormat.money(row['outstanding'])}',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        StatusChip('${row['status']}'),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
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

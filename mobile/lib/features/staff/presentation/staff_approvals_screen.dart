import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import 'staff_controllers.dart';

class StaffApprovalsScreen extends ConsumerStatefulWidget {
  const StaffApprovalsScreen({super.key});

  @override
  ConsumerState<StaffApprovalsScreen> createState() =>
      _StaffApprovalsScreenState();
}

class _StaffApprovalsScreenState extends ConsumerState<StaffApprovalsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  var _busyId = 0;

  @override
  void initState() {
    super.initState();
    _future = ref.read(staffApiProvider).listApprovals();
  }

  void _reload() {
    setState(() {
      _future = ref.read(staffApiProvider).listApprovals();
    });
  }

  Future<void> _decide(int id, {required bool approve}) async {
    setState(() => _busyId = id);
    try {
      final api = ref.read(staffApiProvider);
      if (approve) {
        await api.approveChange(id);
      } else {
        await api.rejectChange(id);
      }
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Request approved' : 'Request rejected'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppFormat.friendlyError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyId = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApprove =
        ref.watch(authControllerProvider).asData?.value?.canApproveFinance ??
            false;

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
                child: ScreenHeader(
                  title: 'Approvals',
                  subtitle: 'Payment reversal requests needing a decision',
                  leading: ScreenBackButton(),
                ),
              ),
              Expanded(
                child: FutureBuilder(
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
                          title: 'Could not load approvals',
                          detail: AppFormat.friendlyError(snapshot.error!),
                        ),
                      );
                    }
                    final items = snapshot.data ?? const [];
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        children: const [
                          AppEmptyCard(
                            icon: Icons.rule_folder_outlined,
                            title: 'All clear',
                            detail:
                                'No finance change requests waiting for review.',
                          ),
                        ],
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.magenta,
                      onRefresh: () async => _reload(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final payment = item['payment'];
                          final requester = item['requester'];
                          final pending = item['status'] == 'pending';
                          final id = (item['id'] as num).toInt();
                          final busy = _busyId == id;

                          return FadeRise(
                            delay: Duration(
                              milliseconds: 40 + (index.clamp(0, 8) * 30),
                            ),
                            child: SectionCard(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(13),
                                        ),
                                        child: const Icon(
                                          Icons.undo_rounded,
                                          color: AppColors.warning,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppFormat.statusLabel(
                                                '${item['type']}',
                                              ),
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14.5,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              payment is Map
                                                  ? 'Receipt ${payment['receipt_number'] ?? payment['id']}'
                                                  : 'Payment',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      StatusChip('${item['status']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.mist
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'By ${requester is Map ? requester['name'] : '—'}\n${item['reason']}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: AppColors.navy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (canApprove && pending) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: busy
                                                ? null
                                                : () => _decide(
                                                      id,
                                                      approve: false,
                                                    ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.danger,
                                              side: const BorderSide(
                                                color: AppColors.danger,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              busy ? '…' : 'Reject',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: busy
                                                ? null
                                                : () => _decide(
                                                      id,
                                                      approve: true,
                                                    ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.navy,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              busy ? '…' : 'Approve',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
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

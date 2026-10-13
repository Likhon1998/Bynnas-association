import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../members/domain/member.dart';
import 'staff_controllers.dart';

final staffMemberDetailProvider = FutureProvider.autoDispose
    .family<({Member member, Map<String, dynamic> balance}), int>((ref, id) async {
  final api = ref.watch(staffApiProvider);
  final member = await api.memberDetail(id);
  final balance = await api.memberBalance(id);
  return (member: member, balance: balance);
});

class StaffMemberDetailScreen extends ConsumerStatefulWidget {
  const StaffMemberDetailScreen({super.key, required this.memberId});

  final int memberId;

  @override
  ConsumerState<StaffMemberDetailScreen> createState() =>
      _StaffMemberDetailScreenState();
}

class _StaffMemberDetailScreenState
    extends ConsumerState<StaffMemberDetailScreen> {
  var _busy = false;

  Future<void> _toggleActive(bool currentlyActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentlyActive ? 'Deactivate member?' : 'Reactivate member?'),
        content: Text(
          currentlyActive
              ? 'They will not be able to sign in until reactivated.'
              : 'They will regain app access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(currentlyActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (confirm != true || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(staffApiProvider);
      if (currentlyActive) {
        await api.deactivateMember(widget.memberId);
      } else {
        await api.reactivateMember(widget.memberId);
      }
      ref.invalidate(staffMemberDetailProvider(widget.memberId));
      ref.invalidate(staffMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyActive ? 'Member deactivated' : 'Member reactivated',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException
                  ? error.message
                  : AppFormat.friendlyError(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffMemberDetailProvider(widget.memberId));

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Member profile',
                leading: const ScreenBackButton(),
                actions: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => context.push(
                      '/staff/members/${widget.memberId}/edit',
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    color: AppColors.navy,
                  ),
                ],
              ),
              Expanded(
                child: state.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormat.friendlyError(error),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              staffMemberDetailProvider(widget.memberId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (data) => ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data.member.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                                StatusChip(
                                  data.member.isActive ? 'active' : 'inactive',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data.member.memberId ?? 'No member ID',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(data.member.email),
                            Text(data.member.phone ?? 'No phone on file'),
                            if (data.member.address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                data.member.address!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Balance',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTile(
                              label: 'Expected',
                              value: AppFormat.money(data.balance['total_due']),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MetricTile(
                              label: 'Paid',
                              value: AppFormat.money(
                                data.balance['total_allocated'],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      MetricTile(
                        label: 'Outstanding',
                        value: AppFormat.money(data.balance['outstanding']),
                        emphasis: true,
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Record payment',
                        icon: Icons.add_card_outlined,
                        onPressed: () => context.push(
                          '/staff/payments/record?memberId=${widget.memberId}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _toggleActive(data.member.isActive),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: data.member.isActive
                              ? AppColors.danger
                              : AppColors.navy,
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: data.member.isActive
                                ? AppColors.danger.withValues(alpha: 0.4)
                                : AppColors.fieldBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          data.member.isActive
                              ? 'Deactivate member'
                              : 'Reactivate member',
                        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notices/presentation/notice_controllers.dart';
import 'staff_controllers.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final dashboard = ref.watch(staffDashboardProvider);
    final unread = ref.watch(unreadCountProvider).asData?.value ?? 0;
    final firstName = user?.name.split(' ').first ?? 'there';

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => ref.read(staffDashboardProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(child: BrandMark(compact: true)),
                    IconButton(
                      tooltip: 'Notices',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/notices'),
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text(
                          '$unread',
                          style: const TextStyle(fontSize: 10),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 22),
                      ),
                      color: AppColors.navy,
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      color: AppColors.navy,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Hello, $firstName',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Staff console · ${AppFormat.roleLabel(user?.role)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                dashboard.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                  error: (error, _) => SectionCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          AppFormat.friendlyError(error),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(staffDashboardProvider.notifier)
                              .refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Expected',
                              value: AppFormat.money(data['expected_dues']),
                              icon: Icons.account_balance_wallet_outlined,
                              accent: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricCard(
                              label: 'Collected',
                              value: AppFormat.money(
                                data['actual_collections'],
                              ),
                              icon: Icons.payments_outlined,
                              accent: const Color(0xFF0F7A45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'Outstanding',
                              value: AppFormat.money(data['outstanding']),
                              icon: Icons.schedule_rounded,
                              accent: AppColors.magenta,
                              emphasizeValue: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricCard(
                              label: 'Collection rate',
                              value: '${data['collection_rate'] ?? '0.00'}%',
                              icon: Icons.pie_chart_outline_rounded,
                              accent: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Operations',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                _OpRow(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Add member',
                  onTap: () => context.push('/staff/members/create'),
                ),
                _OpRow(
                  icon: Icons.groups_outlined,
                  label: 'Members',
                  onTap: () => context.go('/staff/members'),
                ),
                _OpRow(
                  icon: Icons.payments_outlined,
                  label: 'Payments',
                  onTap: () => context.go('/staff/payments'),
                ),
                _OpRow(
                  icon: Icons.add_card_outlined,
                  label: 'Record payment',
                  onTap: () => context.push('/staff/payments/record'),
                ),
                _OpRow(
                  icon: Icons.account_balance_outlined,
                  label: 'Contribution plans',
                  onTap: () => context.push('/staff/plans'),
                ),
                _OpRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Generate dues',
                  onTap: () => context.push('/staff/dues/generate'),
                ),
                _OpRow(
                  icon: Icons.campaign_outlined,
                  label: 'Compose notice',
                  onTap: () => context.push('/staff/notices/compose'),
                ),
                _OpRow(
                  icon: Icons.assessment_outlined,
                  label: 'Reports',
                  onTap: () => context.go('/staff/reports'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accent),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
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
              color: emphasizeValue ? accent : AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 28,
            height: 2.5,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpRow extends StatelessWidget {
  const _OpRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: SectionCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.navy, size: 17),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }
}

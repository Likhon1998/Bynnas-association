import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/service_grid.dart';
import '../../auth/domain/auth_user.dart';
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
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());
    final services = _services(context, user);

    return Scaffold(
      body: BrandAtmosphere(
        intense: true,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () => ref.read(staffDashboardProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                FadeRise(
                  child: Row(
                    children: [
                      const Expanded(child: BrandMark(compact: true)),
                      _HeaderIcon(
                        tooltip: 'Notices',
                        onPressed: () => context.push('/notices'),
                        child: Badge(
                          isLabelVisible: unread > 0,
                          label: Text(
                            '$unread',
                            style: const TextStyle(fontSize: 10),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HeaderIcon(
                        tooltip: 'Sign out',
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        child: const Icon(Icons.logout_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SoftScaleIn(
                  child: _BrandPoster(
                    role: AppFormat.roleLabel(user?.role),
                    today: today,
                  ),
                ),
                const SizedBox(height: 14),
                dashboard.when(
                  loading: () => const _DashboardSkeleton(),
                  error: (error, _) => SectionCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(
                          AppFormat.friendlyError(error),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 13,
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
                  data: (data) => FadeRise(
                    delay: const Duration(milliseconds: 100),
                    child: _CollectionSnapshot(data: data),
                  ),
                ),
                const SizedBox(height: 18),
                FadeRise(
                  delay: const Duration(milliseconds: 150),
                  child: const SectionLabel('Services'),
                ),
                const SizedBox(height: 8),
                ServiceGrid(items: services),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ServiceItem> _services(BuildContext context, AuthUser? user) {
    return [
      ServiceItem(
        icon: Icons.groups_rounded,
        label: 'Members',
        tint: AppColors.blue,
        onTap: () => context.go('/staff/members'),
      ),
      if (user?.canManageMembers ?? false)
        ServiceItem(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add\nMember',
          tint: AppColors.blue,
          onTap: () => context.push('/staff/members/create'),
        ),
      ServiceItem(
        icon: Icons.add_card_rounded,
        label: 'Record\nPay',
        tint: AppColors.magenta,
        onTap: () => context.push('/staff/payments/record'),
      ),
      ServiceItem(
        icon: Icons.payments_rounded,
        label: 'Payments',
        tint: AppColors.magenta,
        onTap: () => context.go('/staff/payments'),
      ),
      ServiceItem(
        icon: Icons.fact_check_rounded,
        label: 'Month\nStatus',
        tint: AppColors.warning,
        onTap: () => context.push('/staff/month-status'),
      ),
      ServiceItem(
        icon: Icons.rule_folder_rounded,
        label: 'Approvals',
        tint: AppColors.warning,
        onTap: () => context.push('/staff/approvals'),
      ),
      ServiceItem(
        icon: Icons.account_balance_rounded,
        label: 'Plans',
        tint: AppColors.navy,
        onTap: () => context.push('/staff/plans'),
      ),
      ServiceItem(
        icon: Icons.calendar_month_rounded,
        label: 'Generate\nDues',
        tint: AppColors.navy,
        onTap: () => context.push('/staff/dues/generate'),
      ),
      ServiceItem(
        icon: Icons.assessment_rounded,
        label: 'Reports',
        tint: AppColors.accent,
        onTap: () => context.go('/staff/reports'),
      ),
      if (user?.canManageNotices ?? false)
        ServiceItem(
          icon: Icons.campaign_rounded,
          label: 'Notice',
          tint: AppColors.accent,
          onTap: () => context.push('/staff/notices/compose'),
        ),
      if (user?.canSendSms ?? false)
        ServiceItem(
          icon: Icons.sms_rounded,
          label: 'SMS',
          tint: const Color(0xFF4A5568),
          onTap: () => context.push('/staff/sms'),
        ),
      if (user?.canManageStaff ?? false)
        ServiceItem(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Staff',
          tint: const Color(0xFF4A5568),
          onTap: () => context.push('/staff/users'),
        ),
      if (user?.canRunBackups ?? false)
        ServiceItem(
          icon: Icons.backup_rounded,
          label: 'Backup',
          tint: const Color(0xFF4A5568),
          onTap: () => context.push('/staff/backup'),
        ),
    ];
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.fieldBorder),
      ),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: child,
        color: AppColors.navy,
      ),
    );
  }
}

class _BrandPoster extends StatelessWidget {
  const _BrandPoster({
    required this.role,
    required this.today,
  });

  final String role;
  final String today;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071226), Color(0xFF122448), Color(0xFF1C3570)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -28,
            top: -36,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.magenta.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: IgnorePointer(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.blue.withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    today.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      role,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Bynnas',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 34,
                  height: 1,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.brandGradient.createShader(bounds),
                child: Text(
                  'ASSOCIATION',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 3.6,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dues · Payments · Notices',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionSnapshot extends StatelessWidget {
  const _CollectionSnapshot({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rate = '${data['collection_rate'] ?? '0.00'}%';

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Outstanding',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rate,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppFormat.money(data['outstanding']),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
              fontSize: 26,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: AppColors.fieldBorder.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Expected',
                  value: AppFormat.money(data['expected_dues']),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.fieldBorder.withValues(alpha: 0.8),
              ),
              Expanded(
                child: _MiniMetric(
                  label: 'Collected',
                  value: AppFormat.money(data['actual_collections']),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignEnd ? 12 : 0,
        right: alignEnd ? 0 : 12,
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.magenta.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

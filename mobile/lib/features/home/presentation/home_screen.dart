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
import '../../auth/presentation/auth_controller.dart';
import '../../finance/presentation/finance_controllers.dart';
import '../../notices/presentation/notice_controllers.dart';
import '../../staff/presentation/staff_home_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value;

    if (user != null && user.isStaff) {
      return const StaffHomeScreen();
    }

    final unread = ref.watch(unreadCountProvider).asData?.value ?? 0;
    final balance = ref.watch(financeBalanceProvider);
    final today = DateFormat('EEEE, d MMM').format(DateTime.now());

    return Scaffold(
      body: BrandAtmosphere(
        intense: true,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () async {
              await ref.read(financeBalanceProvider.notifier).refresh();
              await ref.read(unreadCountProvider.notifier).refresh();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                FadeRise(
                  child: Row(
                    children: [
                      const Expanded(child: BrandMark(compact: true)),
                      _RoundIcon(
                        tooltip: 'Notifications',
                        onPressed: () => context.push('/notifications'),
                        icon: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread'),
                          child: const Icon(Icons.notifications_none_rounded),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundIcon(
                        tooltip: 'Sign out',
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        icon: const Icon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SoftScaleIn(
                  child: _BrandPoster(
                    memberId: user?.memberId,
                    today: today,
                  ),
                ),
                const SizedBox(height: 14),
                if (user != null) ...[
                  FadeRise(
                    delay: const Duration(milliseconds: 100),
                    child: balance.when(
                      loading: () => const SectionCard(
                        child: SizedBox(
                          height: 96,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.magenta,
                            ),
                          ),
                        ),
                      ),
                      error: (_, _) => SectionCard(
                        onTap: () =>
                            ref.read(financeBalanceProvider.notifier).refresh(),
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'Could not load balance · Tap to retry',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      data: (data) => _BalancePanel(
                        outstanding: AppFormat.money(data.outstanding),
                        paid: AppFormat.money(data.totalAllocated),
                        onOpen: () => context.go('/finance'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeRise(
                    delay: const Duration(milliseconds: 150),
                    child: const SectionLabel('Services'),
                  ),
                  const SizedBox(height: 8),
                  ServiceGrid(
                    items: [
                      ServiceItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Finance',
                        tint: AppColors.magenta,
                        onTap: () => context.go('/finance'),
                      ),
                      ServiceItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Payments',
                        tint: AppColors.magenta,
                        onTap: () => context.push('/finance/payments'),
                      ),
                      ServiceItem(
                        icon: Icons.description_rounded,
                        label: 'Statement',
                        tint: AppColors.navy,
                        onTap: () => context.push('/finance/statement'),
                      ),
                      ServiceItem(
                        icon: Icons.campaign_rounded,
                        label: 'Notices',
                        tint: AppColors.accent,
                        badge: unread > 0 ? '$unread' : null,
                        onTap: () => context.go('/notices'),
                      ),
                      ServiceItem(
                        icon: Icons.notifications_rounded,
                        label: 'Alerts',
                        tint: AppColors.accent,
                        badge: unread > 0 ? '$unread' : null,
                        onTap: () => context.push('/notifications'),
                      ),
                      ServiceItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        tint: AppColors.blue,
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.magenta),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPoster extends StatelessWidget {
  const _BrandPoster({
    required this.memberId,
    required this.today,
  });

  final String? memberId;
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
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      'ID  ${memberId ?? 'Pending'}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
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
                'Your dues, payments & notices',
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

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({
    required this.outstanding,
    required this.paid,
    required this.onOpen,
  });

  final String outstanding;
  final String paid;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onOpen,
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
              Text(
                'Details →',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            outstanding,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.magenta,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.7,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paid to date  $paid',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

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
        onPressed: onPressed,
        icon: icon,
        color: AppColors.navy,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: const Text('You will need to sign in again on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _confirmSignOutAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign out all devices?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Every active session will be revoked, including this one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).logoutAll();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name.trim()[0].toUpperCase()
        : 'S';

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              FadeRise(
                child: Text(
                  'Profile',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeRise(
                delay: const Duration(milliseconds: 40),
                child: Text(
                  'Your staff account',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SoftScaleIn(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B1A3A),
                        Color(0xFF1A2F5C),
                        Color(0xFF243B7A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.24),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandDiagonal,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          initial,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Staff',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                AppFormat.roleLabel(user?.role),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeRise(
                delay: const Duration(milliseconds: 100),
                child: const SectionLabel('Account'),
              ),
              const SizedBox(height: 8),
              FadeRise(
                delay: const Duration(milliseconds: 120),
                child: SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                        hint: 'Inbox & alerts',
                        onTap: () => context.push('/notifications'),
                      ),
                      const Divider(height: 1, indent: 64),
                      _ProfileTile(
                        icon: Icons.campaign_outlined,
                        label: 'Notices',
                        hint: 'Association updates',
                        onTap: () => context.push('/notices'),
                      ),
                      if (user?.canManageStaff ?? false) ...[
                        const Divider(height: 1, indent: 64),
                        _ProfileTile(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Staff accounts',
                          hint: 'Manage admin access',
                          onTap: () => context.push('/staff/users'),
                        ),
                      ],
                      if (user?.canRunBackups ?? false) ...[
                        const Divider(height: 1, indent: 64),
                        _ProfileTile(
                          icon: Icons.backup_outlined,
                          label: 'Database backup',
                          hint: 'Create a safe snapshot',
                          onTap: () => context.push('/staff/backup'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeRise(
                delay: const Duration(milliseconds: 160),
                child: const SectionLabel('Session'),
              ),
              const SizedBox(height: 8),
              FadeRise(
                delay: const Duration(milliseconds: 180),
                child: SectionCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        hint: 'End this session',
                        tint: AppColors.navy,
                        onTap: () => _confirmSignOut(context, ref),
                      ),
                      const Divider(height: 1, indent: 64),
                      _ProfileTile(
                        icon: Icons.devices_rounded,
                        label: 'Sign out all devices',
                        hint: 'Revoke every active login',
                        tint: AppColors.danger,
                        onTap: () => _confirmSignOutAll(context, ref),
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.navy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

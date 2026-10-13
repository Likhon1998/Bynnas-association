import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/presentation/auth_controller.dart';

/// Bottom navigation for authenticated member/staff flows.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static bool _hideNav(String path) {
    if (RegExp(r'^/notices/\d+').hasMatch(path)) {
      return true;
    }
    if (RegExp(r'^/finance/payments/\d+').hasMatch(path)) {
      return true;
    }
    if (path.startsWith('/staff/members/create') ||
        (path.startsWith('/staff/members/') &&
            (path.endsWith('/edit') || RegExp(r'/\d+$').hasMatch(path)))) {
      return true;
    }
    if (path.startsWith('/staff/plans') ||
        path.startsWith('/staff/dues') ||
        path.startsWith('/staff/notices')) {
      return true;
    }
    if (path.contains('/record')) {
      return true;
    }
    if (path == '/forgot-password') {
      return true;
    }
    return false;
  }

  static int _indexFor(String path, bool staff) {
    if (staff) {
      if (path.startsWith('/staff/reports')) {
        return 3;
      }
      if (path.startsWith('/staff/payments')) {
        return 2;
      }
      if (path.startsWith('/staff/members')) {
        return 1;
      }
      return 0;
    }
    if (path.startsWith('/profile')) {
      return 3;
    }
    if (path.startsWith('/notices') || path.startsWith('/notifications')) {
      return 2;
    }
    if (path.startsWith('/finance')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).asData?.value;
    final staff = user?.isStaff ?? false;
    final path = GoRouterState.of(context).uri.path;
    final hideNav = _hideNav(path);
    final index = _indexFor(path, staff);

    final destinations = staff
        ? const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Members',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments_rounded),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment_rounded),
              label: 'Reports',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Finance',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Notices',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ];

    final tabPaths = staff
        ? const ['/', '/staff/members', '/staff/payments', '/staff/reports']
        : const ['/', '/finance', '/notices', '/profile'];

    return Scaffold(
      body: child,
      bottomNavigationBar: hideNav
          ? null
          : NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorColor: AppColors.accent.withValues(alpha: 0.14),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return GoogleFonts.plusJakartaSans(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                    color: selected ? AppColors.navy : AppColors.textMuted,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 22,
                    color: selected ? AppColors.accent : AppColors.textMuted,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: index.clamp(0, destinations.length - 1),
                onDestinationSelected: (i) {
                  if (i >= 0 && i < tabPaths.length) {
                    context.go(tabPaths[i]);
                  }
                },
                destinations: destinations,
                backgroundColor: Colors.white.withValues(alpha: 0.98),
                elevation: 0,
                height: 62,
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/finance/presentation/finance_dashboard_screen.dart';
import '../../features/finance/presentation/payment_detail_screen.dart';
import '../../features/finance/presentation/payments_list_screen.dart';
import '../../features/finance/presentation/statement_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/members/presentation/member_profile_screen.dart';
import '../../features/notices/presentation/notice_detail_screen.dart';
import '../../features/notices/presentation/notices_list_screen.dart';
import '../../features/notices/presentation/notifications_inbox_screen.dart';
import '../../features/staff/presentation/staff_approvals_screen.dart';
import '../../features/staff/presentation/staff_backup_screen.dart';
import '../../features/staff/presentation/staff_compose_notice_screen.dart';
import '../../features/staff/presentation/staff_create_member_screen.dart';
import '../../features/staff/presentation/staff_edit_member_screen.dart';
import '../../features/staff/presentation/staff_generate_dues_screen.dart';
import '../../features/staff/presentation/staff_member_detail_screen.dart';
import '../../features/staff/presentation/staff_members_screen.dart';
import '../../features/staff/presentation/staff_month_status_screen.dart';
import '../../features/staff/presentation/staff_payments_screen.dart';
import '../../features/staff/presentation/staff_plans_screen.dart';
import '../../features/staff/presentation/staff_profile_screen.dart';
import '../../features/staff/presentation/staff_record_payment_screen.dart';
import '../../features/staff/presentation/staff_reports_screen.dart';
import '../../features/staff/presentation/staff_sms_screen.dart';
import '../../features/staff/presentation/staff_users_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../theme/app_colors.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';

      if (authState.isLoading) {
        return null;
      }

      final user = authState.asData?.value;
      final isAuthenticated = user != null;

      if (!isAuthenticated && !loggingIn) {
        return '/login';
      }

      if (isAuthenticated && loggingIn) {
        return '/';
      }

      final loc = state.matchedLocation;
      final isStaffRoute = loc.startsWith('/staff');
      final isMemberOnlyRoute = loc == '/profile' ||
          loc == '/finance' ||
          loc == '/finance/payments' ||
          loc == '/finance/statement';

      if (isAuthenticated && isStaffRoute && !user.isStaff) {
        return '/';
      }

      if (isAuthenticated && isMemberOnlyRoute && user.isStaff) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const MemberProfileScreen(),
          ),
          GoRoute(
            path: '/notices',
            name: 'notices',
            builder: (context, state) => const NoticesListScreen(),
          ),
          GoRoute(
            path: '/notices/:id',
            name: 'notice-detail',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return NoticeDetailScreen(noticeId: id);
            },
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsInboxScreen(),
          ),
          GoRoute(
            path: '/finance',
            name: 'finance',
            builder: (context, state) => const FinanceDashboardScreen(),
          ),
          GoRoute(
            path: '/finance/payments',
            name: 'finance-payments',
            builder: (context, state) => const PaymentsListScreen(),
          ),
          GoRoute(
            path: '/finance/payments/:id',
            name: 'finance-payment-detail',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PaymentDetailScreen(paymentId: id);
            },
          ),
          GoRoute(
            path: '/finance/statement',
            name: 'finance-statement',
            builder: (context, state) => const StatementScreen(),
          ),
          GoRoute(
            path: '/staff/members',
            name: 'staff-members',
            builder: (context, state) => const StaffMembersScreen(),
          ),
          GoRoute(
            path: '/staff/members/create',
            name: 'staff-create-member',
            builder: (context, state) => const StaffCreateMemberScreen(),
          ),
          GoRoute(
            path: '/staff/members/:id/edit',
            name: 'staff-edit-member',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return StaffEditMemberScreen(memberId: id);
            },
          ),
          GoRoute(
            path: '/staff/members/:id',
            name: 'staff-member-detail',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return StaffMemberDetailScreen(memberId: id);
            },
          ),
          GoRoute(
            path: '/staff/payments',
            name: 'staff-payments',
            builder: (context, state) => const StaffPaymentsScreen(),
          ),
          GoRoute(
            path: '/staff/payments/record',
            name: 'staff-record-payment',
            builder: (context, state) {
              final raw = state.uri.queryParameters['memberId'];
              final memberId = int.tryParse(raw ?? '');
              return StaffRecordPaymentScreen(memberId: memberId);
            },
          ),
          GoRoute(
            path: '/staff/plans',
            name: 'staff-plans',
            builder: (context, state) => const StaffPlansScreen(),
          ),
          GoRoute(
            path: '/staff/dues/generate',
            name: 'staff-generate-dues',
            builder: (context, state) => const StaffGenerateDuesScreen(),
          ),
          GoRoute(
            path: '/staff/notices/compose',
            name: 'staff-compose-notice',
            builder: (context, state) => const StaffComposeNoticeScreen(),
          ),
          GoRoute(
            path: '/staff/reports',
            name: 'staff-reports',
            builder: (context, state) => const StaffReportsScreen(),
          ),
          GoRoute(
            path: '/staff/profile',
            name: 'staff-profile',
            builder: (context, state) => const StaffProfileScreen(),
          ),
          GoRoute(
            path: '/staff/month-status',
            name: 'staff-month-status',
            builder: (context, state) => const StaffMonthStatusScreen(),
          ),
          GoRoute(
            path: '/staff/sms',
            name: 'staff-sms',
            builder: (context, state) => const StaffSmsScreen(),
          ),
          GoRoute(
            path: '/staff/approvals',
            name: 'staff-approvals',
            builder: (context, state) => const StaffApprovalsScreen(),
          ),
          GoRoute(
            path: '/staff/users',
            name: 'staff-users',
            builder: (context, state) => const StaffUsersScreen(),
          ),
          GoRoute(
            path: '/staff/backup',
            name: 'staff-backup',
            builder: (context, state) => const StaffBackupScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page not found',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'This screen is unavailable.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _ref.listen(authControllerProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

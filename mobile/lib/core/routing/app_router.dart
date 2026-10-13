import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/members/presentation/member_profile_screen.dart';
import '../../features/finance/presentation/finance_dashboard_screen.dart';
import '../../features/finance/presentation/payment_detail_screen.dart';
import '../../features/finance/presentation/payments_list_screen.dart';
import '../../features/finance/presentation/statement_screen.dart';
import '../../features/notices/presentation/notice_detail_screen.dart';
import '../../features/notices/presentation/notices_list_screen.dart';
import '../../features/notices/presentation/notifications_inbox_screen.dart';

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

      final isAuthenticated = authState.asData?.value != null;

      if (!isAuthenticated && !loggingIn) {
        return '/login';
      }

      if (isAuthenticated && loggingIn) {
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
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(state.error?.toString() ?? 'Page not found'),
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

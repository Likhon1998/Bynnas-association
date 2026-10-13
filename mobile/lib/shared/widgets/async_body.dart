import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'app_format.dart';
import 'gradient_button.dart';

class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.emptyTitle = 'Nothing here yet',
    this.emptyDetail = 'Pull to refresh or try again later.',
    this.isEmpty,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyDetail;
  final bool Function(T data)? isEmpty;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (error, _) => _StatePanel(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        detail: AppFormat.friendlyError(error),
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
      data: (items) {
        if (isEmpty?.call(items) ?? false) {
          return _StatePanel(
            icon: Icons.inbox_outlined,
            title: emptyTitle,
            detail: emptyDetail,
            actionLabel: 'Refresh',
            onAction: onRetry,
          );
        }
        return data(items);
      },
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 160,
              child: GradientButton(
                label: actionLabel,
                icon: Icons.refresh_rounded,
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

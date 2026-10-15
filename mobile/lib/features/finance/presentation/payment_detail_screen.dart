import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../staff/presentation/staff_controllers.dart';
import 'finance_controllers.dart';

class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({super.key, required this.paymentId});

  final int paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(financePaymentDetailProvider(paymentId));
    final user = ref.watch(authControllerProvider).asData?.value;
    final isStaff = user?.isStaff ?? false;

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.navy,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.fieldBorder),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Receipt',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: detail.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.magenta),
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
                              financePaymentDetailProvider(paymentId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (payment) => ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    children: [
                      if (payment.isReversed)
                        FadeRise(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    payment.reversalReason?.isNotEmpty == true
                                        ? 'Reversed — ${payment.reversalReason}'
                                        : 'This receipt has been reversed. History is preserved.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SoftScaleIn(
                        child: _ReceiptHero(
                          receiptNumber: payment.receiptNumber,
                          amount: AppFormat.money(payment.amount),
                          status: payment.status,
                          method: payment.method,
                          date: AppFormat.dateTime(payment.receivedAt),
                          onCopy: () {
                            Clipboard.setData(
                              ClipboardData(text: payment.receiptNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Receipt number copied'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      FadeRise(
                        delay: const Duration(milliseconds: 80),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Recorded by',
                                value: payment.recordedByName ?? '—',
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                icon: Icons.payments_outlined,
                                label: 'Method',
                                value: AppFormat.statusLabel(
                                  payment.method ?? '—',
                                ),
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                icon: Icons.event_outlined,
                                label: 'Received',
                                value: AppFormat.dateTime(payment.receivedAt),
                              ),
                              const Divider(height: 1),
                              _InfoRow(
                                icon: Icons.currency_exchange_rounded,
                                label: 'Currency',
                                value: payment.currency,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeRise(
                        delay: const Duration(milliseconds: 120),
                        child: Row(
                          children: [
                            const Expanded(
                              child: SectionLabel('Allocations'),
                            ),
                            Text(
                              '${payment.allocations.length}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (payment.allocations.isEmpty)
                        FadeRise(
                          delay: const Duration(milliseconds: 140),
                          child: SectionCard(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No period allocations on this receipt.',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ...payment.allocations.asMap().entries.map((entry) {
                          final i = entry.key;
                          final line = entry.value;
                          return FadeRise(
                            delay: Duration(milliseconds: 140 + (i * 35)),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SectionCard(
                                padding: const EdgeInsets.all(13),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: line.isReversed
                                            ? AppColors.danger
                                                .withValues(alpha: 0.1)
                                            : AppColors.mist,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: line.isReversed
                                            ? AppColors.danger
                                            : AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            line.periodLabel ?? 'Period',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.navy,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            line.isReversed
                                                ? 'Reversed allocation'
                                                : 'Applied to dues',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppColors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppFormat.money(line.amount),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navy,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      if (isStaff && !payment.isReversed) ...[
                        const SizedBox(height: 20),
                        FadeRise(
                          delay: const Duration(milliseconds: 220),
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmReverse(context, ref),
                            icon: const Icon(Icons.undo_rounded, size: 18),
                            label: const Text('Reverse payment'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color:
                                    AppColors.danger.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _confirmReverse(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reverse payment?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial history is never deleted. Provide a clear reason.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g. Duplicate entry',
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Reverse'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) {
      return;
    }
    try {
      final result = await ref.read(staffApiProvider).requestReverse(
            paymentId: paymentId,
            reason: reason,
          );
      ref.invalidate(financePaymentDetailProvider(paymentId));
      ref.invalidate(staffPaymentsProvider);
      ref.invalidate(staffDashboardProvider);
      if (context.mounted) {
        final immediate = result['immediate'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              immediate
                  ? 'Payment reversed'
                  : 'Reversal submitted for admin approval',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
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
    }
  }
}

class _ReceiptHero extends StatelessWidget {
  const _ReceiptHero({
    required this.receiptNumber,
    required this.amount,
    required this.status,
    required this.method,
    required this.date,
    required this.onCopy,
  });

  final String receiptNumber;
  final String amount;
  final String status;
  final String? method;
  final String date;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071226), Color(0xFF122448), Color(0xFF1C3570)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: IgnorePointer(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.magenta.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'RECEIPT',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppFormat.statusLabel(status),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PressableScale(
                onTap: onCopy,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        receiptNumber,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                amount,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                  letterSpacing: -0.8,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (method != null && method!.isNotEmpty)
                    AppFormat.statusLabel(method),
                  date,
                ].where((e) => e.isNotEmpty && e != '—').join(' · '),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

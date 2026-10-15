import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'staff_controllers.dart';

class StaffPaymentsScreen extends ConsumerStatefulWidget {
  const StaffPaymentsScreen({super.key});

  @override
  ConsumerState<StaffPaymentsScreen> createState() =>
      _StaffPaymentsScreenState();
}

class _StaffPaymentsScreenState extends ConsumerState<StaffPaymentsScreen> {
  final _search = TextEditingController();
  var _query = '';
  var _statusFilter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    final q = _query.trim().toLowerCase();
    return items.where((payment) {
      final status = '${payment['status'] ?? ''}'.toLowerCase();
      if (_statusFilter != 'all' && status != _statusFilter) {
        return false;
      }
      if (q.isEmpty) {
        return true;
      }
      final user = payment['user'];
      final memberName =
          user is Map ? '${user['name'] ?? ''}'.toLowerCase() : '';
      final receipt = '${payment['receipt_number'] ?? ''}'.toLowerCase();
      return memberName.contains(q) || receipt.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(staffPaymentsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/payments/record'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_card_rounded),
        label: Text(
          'Record payment',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Payments',
                subtitle: payments.asData == null
                    ? 'Receipts posted by the association'
                    : '${_filter(payments.asData!.value).length} receipt${_filter(payments.asData!.value).length == 1 ? '' : 's'}',
                leading: context.canPop()
                    ? const ScreenBackButton()
                    : const SizedBox(width: 8),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search receipt or member',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              onPressed: () => setState(() {
                                _search.clear();
                                _query = '';
                              }),
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Posted',
                      selected: _statusFilter == 'posted',
                      onTap: () => setState(() => _statusFilter = 'posted'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Reversed',
                      selected: _statusFilter == 'reversed',
                      onTap: () => setState(() => _statusFilter = 'reversed'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: AsyncBody(
                  value: payments,
                  onRetry: () =>
                      ref.read(staffPaymentsProvider.notifier).refresh(),
                  emptyTitle: 'No payments yet',
                  emptyDetail: 'Record a payment to see receipts here.',
                  isEmpty: (items) => _filter(items).isEmpty,
                  data: (items) {
                    final filtered = _filter(items);
                    return RefreshIndicator(
                      color: AppColors.magenta,
                      onRefresh: () =>
                          ref.read(staffPaymentsProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          return FadeRise(
                            delay: Duration(
                              milliseconds: 30 + (index.clamp(0, 8) * 30),
                            ),
                            child: _PaymentRow(payment: filtered[index]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final id = (payment['id'] as num?)?.toInt() ?? 0;
    final status = '${payment['status'] ?? ''}';
    final method = '${payment['method'] ?? ''}'.replaceAll('_', ' ');
    final user = payment['user'];
    final memberName =
        user is Map ? '${user['name'] ?? 'Member'}' : 'Member';
    final reversed = status.toLowerCase() == 'reversed';

    return SectionCard(
      onTap: () => context.push('/finance/payments/$id'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: reversed
                  ? AppColors.danger.withValues(alpha: 0.1)
                  : AppColors.magenta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              reversed
                  ? Icons.undo_rounded
                  : Icons.receipt_long_rounded,
              color: reversed ? AppColors.danger : AppColors.magenta,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment['receipt_number'] ?? 'Receipt'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    AppFormat.dateTime(payment['received_at']),
                    if (method.isNotEmpty) AppFormat.statusLabel(method),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormat.money(payment['amount']),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: reversed ? AppColors.textMuted : AppColors.navy,
                  fontSize: 14.5,
                  decoration:
                      reversed ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),
              StatusChip(status),
            ],
          ),
        ],
      ),
    );
  }
}

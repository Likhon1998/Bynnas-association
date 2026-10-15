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
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../members/domain/member.dart';
import 'staff_controllers.dart';

class StaffRecordPaymentScreen extends ConsumerStatefulWidget {
  const StaffRecordPaymentScreen({super.key, this.memberId});

  final int? memberId;

  @override
  ConsumerState<StaffRecordPaymentScreen> createState() =>
      _StaffRecordPaymentScreenState();
}

class _StaffRecordPaymentScreenState
    extends ConsumerState<StaffRecordPaymentScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _memberSearchController = TextEditingController();
  final _amountFocus = FocusNode();

  String _method = 'cash';
  bool _submitting = false;
  bool _loadingDues = false;
  String? _error;
  Member? _selectedMember;
  List<Map<String, dynamic>> _dues = const [];
  final Map<int, TextEditingController> _allocControllers = {};
  late final String _idempotencyKey;

  static const _methods = [
    (value: 'cash', label: 'Cash', icon: Icons.payments_rounded),
    (value: 'bank_transfer', label: 'Bank', icon: Icons.account_balance_rounded),
    (value: 'cheque', label: 'Cheque', icon: Icons.receipt_long_rounded),
    (value: 'other', label: 'Other', icon: Icons.more_horiz_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _idempotencyKey =
        'mobile-${DateTime.now().microsecondsSinceEpoch}-$hashCode';
    _amountController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapMember());
  }

  Future<void> _bootstrapMember() async {
    final id = widget.memberId;
    if (id == null) {
      return;
    }
    try {
      final member = await ref.read(staffApiProvider).memberDetail(id);
      if (!mounted) {
        return;
      }
      setState(() => _selectedMember = member);
      await _loadDues();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = AppFormat.friendlyError(error));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _memberSearchController.dispose();
    _amountFocus.dispose();
    for (final c in _allocControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _parseMoney(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) {
      return 0;
    }
    return double.tryParse(cleaned) ?? 0;
  }

  double get _paymentAmount => _parseMoney(_amountController.text);

  double get _allocatedTotal {
    var sum = 0.0;
    for (final c in _allocControllers.values) {
      sum += _parseMoney(c.text);
    }
    return sum;
  }

  double get _remaining =>
      ((_paymentAmount - _allocatedTotal) * 100).round() / 100;

  double get _totalOutstanding {
    var sum = 0.0;
    for (final due in _dues) {
      sum += _parseMoney('${due['outstanding'] ?? 0}');
    }
    return sum;
  }

  String _fmt(double value) => value.toStringAsFixed(2);

  Future<void> _pickMember() async {
    await ref.read(staffMembersProvider.notifier).refresh();
    if (!mounted) {
      return;
    }

    final picked = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final members = ref.watch(staffMembersProvider);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.5,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.fieldBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select member',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search by name, email, or member ID',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _memberSearchController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search members…',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (value) => ref
                            .read(staffMembersProvider.notifier)
                            .search(value.trim()),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: members.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.magenta,
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Text(AppFormat.friendlyError(error)),
                          ),
                          data: (items) {
                            if (items.isEmpty) {
                              return Center(
                                child: Text(
                                  'No members found',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              controller: scrollController,
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final member = items[index];
                                final selected =
                                    _selectedMember?.id == member.id;
                                return Material(
                                  color: selected
                                      ? AppColors.magenta.withValues(alpha: 0.06)
                                      : AppColors.mist.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () =>
                                        Navigator.of(context).pop(member),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          _MemberAvatar(member: member, size: 44),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  member.name,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.navy,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${member.memberId ?? '—'} · ${member.email}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    color: AppColors.textMuted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selected)
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.magenta,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMember = picked;
        _error = null;
      });
      await _loadDues();
    }
  }

  Future<void> _loadDues() async {
    final member = _selectedMember;
    if (member == null) {
      setState(() => _error = 'Select a member first');
      return;
    }
    setState(() {
      _loadingDues = true;
      _error = null;
      _dues = const [];
    });
    try {
      final dues = await ref.read(staffApiProvider).memberOpenDues(member.id);
      for (final c in _allocControllers.values) {
        c.dispose();
      }
      _allocControllers.clear();
      for (final due in dues) {
        final dueId = (due['id'] as num).toInt();
        final controller = TextEditingController();
        controller.addListener(() => setState(() {}));
        _allocControllers[dueId] = controller;
      }
      setState(() => _dues = dues);
    } catch (error) {
      setState(() => _error = AppFormat.friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _loadingDues = false);
      }
    }
  }

  void _clearAllocations() {
    for (final c in _allocControllers.values) {
      c.text = '';
    }
    setState(() {});
  }

  void _applyFull(int dueId, String outstanding) {
    _allocControllers[dueId]?.text = _fmt(_parseMoney(outstanding));
  }

  /// Spread payment amount across open dues (oldest first / list order).
  void _autoAllocate() {
    final amount = _paymentAmount;
    if (amount <= 0) {
      setState(() => _error = 'Enter a payment amount first');
      return;
    }
    var left = amount;
    for (final due in _dues) {
      final dueId = (due['id'] as num).toInt();
      final outstanding = _parseMoney('${due['outstanding'] ?? 0}');
      final apply = left >= outstanding ? outstanding : left;
      _allocControllers[dueId]?.text =
          apply > 0 ? _fmt(apply) : '';
      left = ((left - apply) * 100).round() / 100;
    }
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final member = _selectedMember;
    final amount = _amountController.text.trim();
    if (member == null) {
      setState(() => _error = 'Select a member');
      return;
    }
    if (amount.isEmpty || _paymentAmount <= 0) {
      setState(() => _error = 'Enter a valid payment amount');
      _amountFocus.requestFocus();
      return;
    }
    if (_allocatedTotal - _paymentAmount > 0.001) {
      setState(
        () => _error =
            'Allocated ${_fmt(_allocatedTotal)} exceeds payment ${_fmt(_paymentAmount)}',
      );
      return;
    }

    final allocations = <Map<String, dynamic>>[];
    for (final entry in _allocControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty && _parseMoney(value) > 0) {
        allocations.add({
          'member_due_id': entry.key,
          'amount': _fmt(_parseMoney(value)),
        });
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref.read(staffApiProvider).recordPayment(
            userId: member.id,
            amount: _fmt(_paymentAmount),
            method: _method,
            idempotencyKey: _idempotencyKey,
            notes: _notesController.text.trim(),
            allocations: allocations,
          );
      ref.invalidate(staffPaymentsProvider);
      ref.invalidate(staffDashboardProvider);

      final data = result['data'];
      final paymentId = data is Map ? data['id'] : null;

      if (!mounted) {
        return;
      }

      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentId != null
                ? 'Payment recorded · Receipt ready'
                : 'Payment recorded',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (paymentId is num) {
        context.pushReplacement('/finance/payments/${paymentId.toInt()}');
      } else {
        context.pop();
      }
    } catch (error) {
      setState(() {
        _error = error is AppException
            ? error.message
            : AppFormat.friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = _selectedMember;
    final overAllocated = _allocatedTotal - _paymentAmount > 0.001;
    final canSubmit = member != null &&
        _paymentAmount > 0 &&
        !_submitting &&
        !overAllocated;

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                  children: [
                    const ScreenHeader(
                      title: 'Record payment',
                      subtitle: 'Post a receipt and allocate to open dues',
                      leading: ScreenBackButton(),
                    ),
                    const SizedBox(height: 6),
                    FadeRise(
                      child: _MemberPickerCard(
                        member: member,
                        onTap: _pickMember,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeRise(
                      delay: const Duration(milliseconds: 60),
                      child: _AmountCard(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        outstanding: member == null || _dues.isEmpty
                            ? null
                            : _totalOutstanding,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeRise(
                      delay: const Duration(milliseconds: 100),
                      child: _MethodPicker(
                        methods: _methods,
                        selected: _method,
                        onChanged: (value) => setState(() => _method = value),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeRise(
                      delay: const Duration(milliseconds: 130),
                      child: SectionCard(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Reference, cheque no., remark…',
                            prefixIcon: const Icon(Icons.notes_rounded),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeRise(
                      delay: const Duration(milliseconds: 160),
                      child: _DuesHeader(
                        count: _dues.length,
                        loading: _loadingDues,
                        enabled: member != null && !_loadingDues,
                        onRefresh: _loadDues,
                        onAuto: member != null &&
                                _dues.isNotEmpty &&
                                _paymentAmount > 0
                            ? _autoAllocate
                            : null,
                        onClear: _dues.isNotEmpty && _allocatedTotal > 0
                            ? _clearAllocations
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingDues)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.magenta,
                          ),
                        ),
                      )
                    else if (member == null)
                      _EmptyHint(
                        icon: Icons.person_search_rounded,
                        text: 'Select a member to load open dues.',
                      )
                    else if (_dues.isEmpty)
                      _EmptyHint(
                        icon: Icons.fact_check_outlined,
                        text: 'No open dues — you can still post an unallocated payment.',
                      )
                    else
                      ..._dues.asMap().entries.map((entry) {
                        final index = entry.key;
                        final due = entry.value;
                        final dueId = (due['id'] as num).toInt();
                        final period = due['period'];
                        final label = period is Map
                            ? '${period['label']}'
                            : 'Due #$dueId';
                        final outstanding = '${due['outstanding'] ?? '0.00'}';
                        return FadeRise(
                          delay: Duration(
                            milliseconds: 180 + (index.clamp(0, 6) * 35),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DueAllocRow(
                              label: label,
                              outstanding: outstanding,
                              controller: _allocControllers[dueId]!,
                              onFull: () => _applyFull(dueId, outstanding),
                            ),
                          ),
                        );
                      }),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF9F1239),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _SubmitBar(
                amount: _paymentAmount,
                allocated: _allocatedTotal,
                remaining: _remaining,
                overAllocated: overAllocated,
                canSubmit: canSubmit,
                submitting: _submitting,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberPickerCard extends StatelessWidget {
  const _MemberPickerCard({
    required this.member,
    required this.onTap,
  });

  final Member? member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(
        children: [
          if (member == null)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: AppColors.navy,
              ),
            )
          else
            _MemberAvatar(member: member!, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member == null ? 'Select member' : member!.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member == null
                      ? 'Required · tap to search'
                      : '${member!.memberId ?? '—'} · ${member!.email}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.magenta.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              member == null ? 'Choose' : 'Change',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.magenta,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.size});

  final Member member;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: member.photoUrl == null ? AppColors.brandDiagonal : null,
        image: member.photoUrl != null
            ? DecorationImage(
                image: NetworkImage(member.photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: member.photoUrl == null
          ? Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36,
              ),
            )
          : null,
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.controller,
    required this.focusNode,
    this.outstanding,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double? outstanding;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Amount received',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const Spacer(),
              if (outstanding != null && outstanding! > 0)
                GestureDetector(
                  onTap: () {
                    controller.text = outstanding!.toStringAsFixed(2);
                  },
                  child: Text(
                    'Fill outstanding',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.magenta,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '৳',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.magenta,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w800,
                      fontSize: 32,
                      letterSpacing: -0.8,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              Text(
                'BDT',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (outstanding != null) ...[
            const SizedBox(height: 10),
            Text(
              'Open dues total  ${AppFormat.money(outstanding!.toStringAsFixed(2))}',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({
    required this.methods,
    required this.selected,
    required this.onChanged,
  });

  final List<({String value, String label, IconData icon})> methods;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment method',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < methods.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _MethodChip(
                    label: methods[i].label,
                    icon: methods[i].icon,
                    selected: selected == methods[i].value,
                    onTap: () => onChanged(methods[i].value),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navy
              : AppColors.mist.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.navy
                : AppColors.fieldBorder.withValues(alpha: 0.9),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppColors.navy,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: selected ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuesHeader extends StatelessWidget {
  const _DuesHeader({
    required this.count,
    required this.loading,
    required this.enabled,
    required this.onRefresh,
    this.onAuto,
    this.onClear,
  });

  final int count;
  final bool loading;
  final bool enabled;
  final VoidCallback onRefresh;
  final VoidCallback? onAuto;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Allocate to dues',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            fontSize: 15,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Clear'),
          ),
        if (onAuto != null)
          TextButton(
            onPressed: onAuto,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.magenta,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Auto'),
          ),
        IconButton(
          tooltip: 'Refresh dues',
          onPressed: enabled ? onRefresh : null,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
          color: AppColors.navy,
        ),
      ],
    );
  }
}

class _DueAllocRow extends StatelessWidget {
  const _DueAllocRow({
    required this.label,
    required this.outstanding,
    required this.controller,
    required this.onFull,
  });

  final String label;
  final String outstanding;
  final TextEditingController controller;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Due ${AppFormat.money(outstanding)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Allocate',
                    prefixText: '৳ ',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onFull,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.magenta,
                  backgroundColor: AppColors.magenta.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Full',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 28),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.amount,
    required this.allocated,
    required this.remaining,
    required this.overAllocated,
    required this.canSubmit,
    required this.submitting,
    required this.onSubmit,
  });

  final double amount;
  final double allocated;
  final double remaining;
  final bool overAllocated;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppColors.fieldBorder.withValues(alpha: 0.9)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (amount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    _SummaryPill(
                      label: 'Paid',
                      value: AppFormat.money(amount.toStringAsFixed(2)),
                    ),
                    const SizedBox(width: 8),
                    _SummaryPill(
                      label: 'Allocated',
                      value: AppFormat.money(allocated.toStringAsFixed(2)),
                      accent: overAllocated
                          ? const Color(0xFF9F1239)
                          : AppColors.navy,
                    ),
                    const SizedBox(width: 8),
                    _SummaryPill(
                      label: overAllocated ? 'Over' : 'Left',
                      value: AppFormat.money(
                        (overAllocated ? allocated - amount : remaining)
                            .abs()
                            .toStringAsFixed(2),
                      ),
                      accent: overAllocated
                          ? const Color(0xFF9F1239)
                          : AppColors.magenta,
                    ),
                  ],
                ),
              ),
            GradientButton(
              label: submitting ? 'Saving…' : 'Save payment',
              icon: Icons.check_rounded,
              isLoading: submitting,
              onPressed: canSubmit ? onSubmit : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.mist.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: accent ?? AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

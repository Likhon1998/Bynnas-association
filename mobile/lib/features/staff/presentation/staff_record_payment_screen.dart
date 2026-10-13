import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
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
  String _method = 'cash';
  bool _submitting = false;
  bool _loadingDues = false;
  String? _error;
  Member? _selectedMember;
  List<Map<String, dynamic>> _dues = const [];
  final Map<int, TextEditingController> _allocControllers = {};
  late final String _idempotencyKey;

  @override
  void initState() {
    super.initState();
    _idempotencyKey =
        'mobile-${DateTime.now().microsecondsSinceEpoch}-$hashCode';
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
    for (final c in _allocControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final members = ref.watch(staffMembersProvider);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                      const SizedBox(height: 14),
                      Text(
                        'Select member',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _memberSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search name, email, member ID',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (value) => ref
                            .read(staffMembersProvider.notifier)
                            .search(value.trim()),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: members.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
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
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final member = items[index];
                                return ListTile(
                                  title: Text(
                                    member.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${member.memberId ?? '—'} · ${member.email}',
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(member),
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
        _allocControllers[dueId] = TextEditingController();
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

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final member = _selectedMember;
    final amount = _amountController.text.trim();
    if (member == null || amount.isEmpty) {
      setState(() => _error = 'Select a member and enter an amount');
      return;
    }

    final allocations = <Map<String, dynamic>>[];
    for (final entry in _allocControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        allocations.add({
          'member_due_id': entry.key,
          'amount': value,
        });
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(staffApiProvider).recordPayment(
            userId: member.id,
            amount: amount,
            method: _method,
            idempotencyKey: _idempotencyKey,
            notes: _notesController.text.trim(),
            allocations: allocations,
          );
      ref.invalidate(staffPaymentsProvider);
      ref.invalidate(staffDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded')),
        );
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

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              const ScreenHeader(
                title: 'Record payment',
                subtitle: 'Allocate cash or bank receipts to open dues',
                leading: ScreenBackButton(),
              ),
              const SizedBox(height: 8),
              SectionCard(
                onTap: _pickMember,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_search_rounded,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member == null ? 'Select member' : member.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member == null
                                ? 'Search by name, email, or member ID'
                                : '${member.memberId ?? '—'} · ${member.email}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (BDT)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _method,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(
                    value: 'bank_transfer',
                    child: Text('Bank transfer'),
                  ),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _method = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Method',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Open dues',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: member == null || _loadingDues ? null : _loadDues,
                    child: Text(_loadingDues ? 'Loading…' : 'Refresh'),
                  ),
                ],
              ),
              if (_loadingDues)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(color: AppColors.accent),
                )
              else if (_dues.isEmpty)
                Text(
                  member == null
                      ? 'Select a member to load open dues.'
                      : 'No open dues for this member.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                  ),
                )
              else
                ..._dues.map((due) {
                  final dueId = (due['id'] as num).toInt();
                  final period = due['period'];
                  final label = period is Map
                      ? '${period['label']}'
                      : 'Due #$dueId';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _allocControllers[dueId],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '$label · outstanding ${AppFormat.money(due['outstanding'])}',
                      ),
                    ),
                  );
                }),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9F1239),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: _submitting ? 'Saving…' : 'Save payment',
                icon: Icons.check_rounded,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

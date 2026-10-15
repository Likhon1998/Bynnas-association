import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'staff_controllers.dart';

final staffPlansProvider =
    AsyncNotifierProvider<StaffPlansNotifier, List<Map<String, dynamic>>>(
  StaffPlansNotifier.new,
);

class StaffPlansNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() =>
      ref.read(staffApiProvider).listPlans();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(staffApiProvider).listPlans());
  }
}

class StaffPlansScreen extends ConsumerStatefulWidget {
  const StaffPlansScreen({super.key});

  @override
  ConsumerState<StaffPlansScreen> createState() => _StaffPlansScreenState();
}

class _StaffPlansScreenState extends ConsumerState<StaffPlansScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  var _creating = false;
  var _formOpen = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_creating) {
      return;
    }
    if (_name.text.trim().isEmpty ||
        _code.text.trim().isEmpty ||
        _amount.text.trim().isEmpty) {
      setState(() => _error = 'Name, code, and amount are required');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      await ref.read(staffApiProvider).createPlan(
            name: _name.text.trim(),
            code: _code.text.trim().toUpperCase(),
            defaultAmount: _amount.text.trim(),
            description: _description.text.trim(),
          );
      _name.clear();
      _code.clear();
      _amount.clear();
      _description.clear();
      await ref.read(staffPlansProvider.notifier).refresh();
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() => _formOpen = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contribution plan created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _error = error is AppException
            ? error.message
            : AppFormat.friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(staffPlansProvider);
    final count = plans.asData?.value.length;

    return Scaffold(
      floatingActionButton: !_formOpen
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _formOpen = true),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'New plan',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: () => ref.read(staffPlansProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
              children: [
                ScreenHeader(
                  title: 'Contribution plans',
                  subtitle: count == null
                      ? 'Amounts used when generating monthly dues'
                      : '$count plan${count == 1 ? '' : 's'} · used for dues',
                  leading: const ScreenBackButton(),
                ),
                if (_formOpen) ...[
                  FadeRise(
                    child: SectionCard(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'New plan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: () =>
                                    setState(() => _formOpen = false),
                                icon: const Icon(Icons.close_rounded),
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              hintText: 'Monthly contribution',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _code,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Code',
                              hintText: 'MONTHLY',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[\d.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Default amount',
                              prefixText: '৳ ',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _description,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            AppErrorBanner(_error!),
                          ],
                          const SizedBox(height: 14),
                          GradientButton(
                            label: _creating ? 'Saving…' : 'Create plan',
                            icon: Icons.check_rounded,
                            isLoading: _creating,
                            onPressed: _creating ? null : _create,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                FadeRise(
                  delay: const Duration(milliseconds: 60),
                  child: const SectionLabel('Existing plans'),
                ),
                const SizedBox(height: 10),
                plans.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.magenta),
                    ),
                  ),
                  error: (error, _) => AppEmptyCard(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load plans',
                    detail: AppFormat.friendlyError(error),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const AppEmptyCard(
                        icon: Icons.account_balance_outlined,
                        title: 'No plans yet',
                        detail: 'Create a contribution plan to generate dues.',
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          FadeRise(
                            delay: Duration(
                              milliseconds: 80 + (i.clamp(0, 8) * 30),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PlanRow(plan: items[i]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan});

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    final active = plan['is_active'] == true;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan['name']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${plan['code']}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormat.money(plan['default_amount']),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppColors.magenta,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              StatusChip(active ? 'active' : 'inactive'),
            ],
          ),
        ],
      ),
    );
  }
}

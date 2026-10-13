import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution plan created')),
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

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => ref.read(staffPlansProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                const ScreenHeader(
                  title: 'Contribution plans',
                  subtitle: 'Monthly dues amounts used when generating periods',
                  leading: ScreenBackButton(),
                ),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'New plan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                          helperText: 'e.g. MONTHLY',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Default amount (BDT)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _description,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      GradientButton(
                        label: _creating ? 'Saving…' : 'Create plan',
                        icon: Icons.add_rounded,
                        isLoading: _creating,
                        onPressed: _creating ? null : _create,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Existing plans',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                plans.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                  ),
                  error: (error, _) => Text(AppFormat.friendlyError(error)),
                  data: (items) {
                    if (items.isEmpty) {
                      return Text(
                        'No plans yet. Create one above.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                        ),
                      );
                    }
                    return Column(
                      children: items
                          .map(
                            (plan) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SectionCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${plan['name']}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.navy,
                                            ),
                                          ),
                                          Text(
                                            '${plan['code']} · ${AppFormat.money(plan['default_amount'])}',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(
                                      (plan['is_active'] == true)
                                          ? 'active'
                                          : 'inactive',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
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

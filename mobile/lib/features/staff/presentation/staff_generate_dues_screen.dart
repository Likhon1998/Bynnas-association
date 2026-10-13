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
import 'staff_controllers.dart';
import 'staff_plans_screen.dart';

class StaffGenerateDuesScreen extends ConsumerStatefulWidget {
  const StaffGenerateDuesScreen({super.key});

  @override
  ConsumerState<StaffGenerateDuesScreen> createState() =>
      _StaffGenerateDuesScreenState();
}

class _StaffGenerateDuesScreenState
    extends ConsumerState<StaffGenerateDuesScreen> {
  late int _year;
  late int _month;
  int? _planId;
  var _submitting = false;
  String? _error;
  String? _result;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffPlansProvider.notifier).refresh();
    });
  }

  Future<void> _generate() async {
    if (_submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });
    try {
      final payload = await ref.read(staffApiProvider).generateDues(
            year: _year,
            month: _month,
            contributionPlanId: _planId,
          );
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final created = data['created'] ?? 0;
      final reused = data['reused'] ?? 0;
      final period = data['period'];
      final label = period is Map ? '${period['label']}' : '$_year-$_month';
      ref.invalidate(staffDashboardProvider);
      setState(() {
        _result =
            '$label · created $created · already existed $reused';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dues generated for $label')),
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
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(staffPlansProvider);
    final years = List.generate(6, (i) => DateTime.now().year - 1 + i);

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              const ScreenHeader(
                title: 'Generate dues',
                subtitle: 'Create monthly obligations for active members',
                leading: ScreenBackButton(),
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _year,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _year = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _month,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1}'.padLeft(2, '0')),
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _month = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    plans.when(
                      loading: () => const LinearProgressIndicator(
                        color: AppColors.accent,
                      ),
                      error: (error, _) =>
                          Text(AppFormat.friendlyError(error)),
                      data: (items) {
                        return DropdownButtonFormField<int?>(
                          // ignore: deprecated_member_use
                          value: _planId,
                          decoration: const InputDecoration(
                            labelText: 'Plan (optional)',
                            helperText: 'Leave empty to use all active plans',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All active plans'),
                            ),
                            ...items.map(
                              (plan) => DropdownMenuItem<int?>(
                                value: (plan['id'] as num).toInt(),
                                child: Text(
                                  '${plan['name']} · ${AppFormat.money(plan['default_amount'])}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _planId = v),
                        );
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_result != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _result!,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    GradientButton(
                      label: _submitting ? 'Generating…' : 'Generate dues',
                      icon: Icons.calendar_month_outlined,
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _generate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

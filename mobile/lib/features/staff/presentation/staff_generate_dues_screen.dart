import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
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

  String get _periodLabel {
    final date = DateTime(_year, _month);
    return DateFormat('MMMM yyyy').format(date);
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
      final label = period is Map ? '${period['label']}' : _periodLabel;
      ref.invalidate(staffDashboardProvider);
      HapticFeedback.mediumImpact();
      setState(() {
        _result =
            '$label · created $created · already existed $reused';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dues generated for $label'),
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
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(staffPlansProvider);
    final years = List.generate(6, (i) => DateTime.now().year - 1 + i);
    final months = List.generate(12, (i) => i + 1);

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            children: [
              const ScreenHeader(
                title: 'Generate dues',
                subtitle: 'Create monthly obligations for active members',
                leading: ScreenBackButton(),
              ),
              FadeRise(
                child: SectionCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Period',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _periodLabel,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Year',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final y in years)
                            AppFilterChip(
                              label: '$y',
                              selected: _year == y,
                              onTap: () => setState(() => _year = y),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Month',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final m in months)
                            AppFilterChip(
                              label: DateFormat('MMM')
                                  .format(DateTime(_year, m)),
                              selected: _month == m,
                              onTap: () => setState(() => _month = m),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeRise(
                delay: const Duration(milliseconds: 80),
                child: SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contribution plan',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      plans.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.magenta,
                            ),
                          ),
                        ),
                        error: (error, _) =>
                            AppErrorBanner(AppFormat.friendlyError(error)),
                        data: (items) {
                          return Column(
                            children: [
                              _PlanOption(
                                selected: _planId == null,
                                title: 'All active plans',
                                subtitle: 'Generate for every active plan',
                                onTap: () => setState(() => _planId = null),
                              ),
                              for (final plan in items) ...[
                                const SizedBox(height: 8),
                                _PlanOption(
                                  selected: _planId ==
                                      (plan['id'] as num).toInt(),
                                  title: '${plan['name']}',
                                  subtitle:
                                      '${plan['code']} · ${AppFormat.money(plan['default_amount'])}',
                                  onTap: () => setState(
                                    () => _planId =
                                        (plan['id'] as num).toInt(),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AppErrorBanner(_error!),
              ],
              if (_result != null) ...[
                const SizedBox(height: 12),
                AppSuccessBanner(_result!),
              ],
              const SizedBox(height: 20),
              FadeRise(
                delay: const Duration(milliseconds: 120),
                child: GradientButton(
                  label: _submitting ? 'Generating…' : 'Generate dues',
                  icon: Icons.calendar_month_rounded,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _generate,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Safe to re-run — existing dues for the period are reused, not duplicated.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.magenta.withValues(alpha: 0.07)
              : AppColors.mist.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.magenta.withValues(alpha: 0.45)
                : AppColors.fieldBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.magenta : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

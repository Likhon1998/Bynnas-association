import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../members/domain/member.dart';
import '../../notices/presentation/notice_controllers.dart';
import 'staff_controllers.dart';

class StaffComposeNoticeScreen extends ConsumerStatefulWidget {
  const StaffComposeNoticeScreen({super.key});

  @override
  ConsumerState<StaffComposeNoticeScreen> createState() =>
      _StaffComposeNoticeScreenState();
}

class _StaffComposeNoticeScreenState
    extends ConsumerState<StaffComposeNoticeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  var _publishNow = true;
  var _submitting = false;
  String _audience = 'all_active_members';
  final Set<int> _selectedMemberIds = {};
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickMembers() async {
    await ref.read(staffMembersProvider.notifier).refresh();
    if (!mounted) {
      return;
    }
    final members =
        ref.read(staffMembersProvider).asData?.value ?? const <Member>[];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
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
                        'Select members',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final m = members[index];
                            final selected =
                                _selectedMemberIds.contains(m.id);
                            return Material(
                              color: selected
                                  ? AppColors.magenta.withValues(alpha: 0.07)
                                  : AppColors.mist.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                              child: CheckboxListTile(
                                value: selected,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                activeColor: AppColors.magenta,
                                title: Text(
                                  m.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                subtitle: Text(m.memberId ?? m.email),
                                onChanged: (v) {
                                  setModal(() {
                                    if (v == true) {
                                      _selectedMemberIds.add(m.id);
                                    } else {
                                      _selectedMemberIds.remove(m.id);
                                    }
                                  });
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      GradientButton(
                        label: 'Done (${_selectedMemberIds.length})',
                        icon: Icons.check_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = 'Title and body are required');
      return;
    }
    if (_audience == 'selected_members' && _selectedMemberIds.isEmpty) {
      setState(() => _error = 'Select at least one member');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = ref.read(staffApiProvider);
      var notice = await api.createNotice(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audienceType: _audience,
        memberIds: _audience == 'selected_members'
            ? _selectedMemberIds.toList()
            : null,
      );
      if (_publishNow) {
        notice = await api.publishNotice(notice.id);
      }
      ref.invalidate(noticesListProvider);
      if (!mounted) {
        return;
      }
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _publishNow ? 'Notice published' : 'Notice saved as draft',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/notices/${notice.id}');
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
    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
            children: [
              const ScreenHeader(
                title: 'Compose notice',
                subtitle: 'Reach all members or a selected group',
                leading: ScreenBackButton(),
              ),
              FadeRise(
                child: SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _body,
                        minLines: 5,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          alignLabelWithHint: true,
                          hintText: 'Write the notice members will read…',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeRise(
                delay: const Duration(milliseconds: 60),
                child: SectionCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Audience',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AudienceOption(
                        selected: _audience == 'all_active_members',
                        title: 'All active members',
                        subtitle: 'Everyone with an active membership',
                        onTap: () => setState(
                          () => _audience = 'all_active_members',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AudienceOption(
                        selected: _audience == 'selected_members',
                        title: 'Selected members',
                        subtitle: _selectedMemberIds.isEmpty
                            ? 'Choose specific people'
                            : '${_selectedMemberIds.length} selected',
                        onTap: () => setState(
                          () => _audience = 'selected_members',
                        ),
                      ),
                      if (_audience == 'selected_members') ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickMembers,
                          icon: const Icon(Icons.group_add_outlined),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: AppColors.fieldBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          label: Text(
                            _selectedMemberIds.isEmpty
                                ? 'Choose members'
                                : '${_selectedMemberIds.length} selected · Change',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Publish immediately',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _publishNow
                              ? 'Members will be notified now'
                              : 'Save as draft for later',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        value: _publishNow,
                        activeThumbColor: AppColors.magenta,
                        onChanged: (v) => setState(() => _publishNow = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                AppErrorBanner(_error!),
              ],
              const SizedBox(height: 20),
              FadeRise(
                delay: const Duration(milliseconds: 100),
                child: GradientButton(
                  label: _submitting
                      ? 'Saving…'
                      : (_publishNow ? 'Publish notice' : 'Save draft'),
                  icon: Icons.campaign_rounded,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceOption extends StatelessWidget {
  const _AudienceOption({
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
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.mist.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.fieldBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.accent : AppColors.textMuted,
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

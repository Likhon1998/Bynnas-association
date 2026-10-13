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
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = 'Title and body are required');
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
      );
      if (_publishNow) {
        notice = await api.publishNotice(notice.id);
      }
      ref.invalidate(noticesListProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _publishNow ? 'Notice published' : 'Notice saved as draft',
          ),
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              const ScreenHeader(
                title: 'Compose notice',
                subtitle: 'Send updates to all active members',
                leading: ScreenBackButton(),
              ),
              SectionCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _body,
                      minLines: 5,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Publish immediately',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      subtitle: Text(
                        _publishNow
                            ? 'Members will receive the notice now'
                            : 'Save as draft for later',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      value: _publishNow,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _publishNow = v),
                    ),
                  ],
                ),
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
              const SizedBox(height: 20),
              GradientButton(
                label: _submitting
                    ? 'Saving…'
                    : (_publishNow ? 'Publish notice' : 'Save draft'),
                icon: Icons.campaign_outlined,
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

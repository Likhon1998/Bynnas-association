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
import 'staff_controllers.dart';
import 'staff_member_detail_screen.dart';

class StaffEditMemberScreen extends ConsumerStatefulWidget {
  const StaffEditMemberScreen({super.key, required this.memberId});

  final int memberId;

  @override
  ConsumerState<StaffEditMemberScreen> createState() =>
      _StaffEditMemberScreenState();
}

class _StaffEditMemberScreenState extends ConsumerState<StaffEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  var _hydrated = false;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_hydrated) {
      return;
    }
    final member =
        ref.read(staffMemberDetailProvider(widget.memberId)).asData?.value.member;
    if (member == null) {
      return;
    }
    _name.text = member.name;
    _email.text = member.email;
    _phone.text = member.phone ?? '';
    _address.text = member.address ?? '';
    _notes.text = member.notes ?? '';
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(staffApiProvider).updateMember(
            widget.memberId,
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            notes: _notes.text.trim(),
          );
      ref.invalidate(staffMemberDetailProvider(widget.memberId));
      ref.invalidate(staffMembersProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member updated')),
      );
      context.pop();
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
    final detail = ref.watch(staffMemberDetailProvider(widget.memberId));
    _hydrate();

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: detail.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (error, _) => Center(
              child: Text(AppFormat.friendlyError(error)),
            ),
            data: (_) => Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  const ScreenHeader(
                    title: 'Edit member',
                    leading: ScreenBackButton(),
                  ),
                  SectionCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Valid email required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          decoration: const InputDecoration(labelText: 'Phone'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _address,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Address'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notes,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Notes'),
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
                    label: _submitting ? 'Saving…' : 'Save changes',
                    icon: Icons.check_rounded,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

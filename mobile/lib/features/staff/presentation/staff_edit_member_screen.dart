import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
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
  final _occupation = TextEditingController();
  final _notes = TextEditingController();
  var _hydrated = false;
  var _submitting = false;
  String? _error;
  String? _existingPhotoUrl;
  Uint8List? _newPhotoBytes;
  String? _newPhotoName;
  String? _newPhotoPath;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _occupation.dispose();
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
    _occupation.text = member.occupation ?? '';
    _notes.text = member.notes ?? '';
    _existingPhotoUrl = member.photoUrl;
    _hydrated = true;
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() {
      _newPhotoBytes = bytes;
      _newPhotoName = file.name;
      _newPhotoPath = file.path;
    });
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
      final api = ref.read(staffApiProvider);
      await api.updateMember(
        widget.memberId,
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        occupation: _occupation.text.trim(),
        notes: _notes.text.trim(),
      );
      if (_newPhotoBytes != null) {
        await api.uploadMemberPhoto(
          widget.memberId,
          bytes: _newPhotoBytes,
          filePath: _newPhotoPath,
          filename: _newPhotoName ?? 'photo.jpg',
        );
      }
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
              child: CircularProgressIndicator(color: AppColors.magenta),
            ),
            error: (error, _) => Center(
              child: Text(AppFormat.friendlyError(error)),
            ),
            data: (_) => Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                      children: [
                        const FadeRise(
                          child: ScreenHeader(
                            title: 'Edit member',
                            subtitle: 'Update profile details and photo',
                            leading: ScreenBackButton(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 60),
                          child: SectionCard(
                            gradient: true,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                PressableScale(
                                  onTap: _pickPhoto,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          gradient: _newPhotoBytes == null &&
                                                  _existingPhotoUrl == null
                                              ? AppColors.brandDiagonal
                                              : null,
                                          image: _newPhotoBytes != null
                                              ? DecorationImage(
                                                  image: MemoryImage(
                                                    _newPhotoBytes!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : _existingPhotoUrl != null
                                                  ? DecorationImage(
                                                      image: NetworkImage(
                                                        _existingPhotoUrl!,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: _newPhotoBytes == null &&
                                                _existingPhotoUrl == null
                                            ? Text(
                                                _name.text.isNotEmpty
                                                    ? _name.text[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 26,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.navy,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.photo_camera_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Profile photo',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _newPhotoBytes != null
                                            ? 'New photo selected'
                                            : 'Tap to change photo',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.textMuted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: _pickPhoto,
                                        icon: const Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Change photo'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.navy,
                                          side: const BorderSide(
                                            color: AppColors.fieldBorder,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const FadeRise(
                          delay: Duration(milliseconds: 100),
                          child: SectionLabel('Identity'),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 120),
                          child: SectionCard(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _name,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon:
                                        Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _occupation,
                                  decoration: const InputDecoration(
                                    labelText: 'Occupation',
                                    prefixIcon:
                                        Icon(Icons.work_outline_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const FadeRise(
                          delay: Duration(milliseconds: 150),
                          child: SectionLabel('Contact'),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 170),
                          child: SectionCard(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon:
                                        Icon(Icons.mail_outline_rounded),
                                  ),
                                  validator: (v) =>
                                      v == null || !v.contains('@')
                                          ? 'Valid email required'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _address,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'Address',
                                    prefixIcon: Icon(Icons.home_outlined),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const FadeRise(
                          delay: Duration(milliseconds: 190),
                          child: SectionLabel('Staff notes'),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 210),
                          child: SectionCard(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: TextFormField(
                              controller: _notes,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Internal notes',
                                prefixIcon: Icon(Icons.notes_rounded),
                                alignLabelWithHint: true,
                              ),
                            ),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color:
                              AppColors.fieldBorder.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    child: GradientButton(
                      label: _submitting ? 'Saving…' : 'Save changes',
                      icon: Icons.check_rounded,
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _submit,
                    ),
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

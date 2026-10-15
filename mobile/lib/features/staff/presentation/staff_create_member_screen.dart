import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import 'staff_controllers.dart';

class StaffCreateMemberScreen extends ConsumerStatefulWidget {
  const StaffCreateMemberScreen({super.key});

  @override
  ConsumerState<StaffCreateMemberScreen> createState() =>
      _StaffCreateMemberScreenState();
}

class _StaffCreateMemberScreenState
    extends ConsumerState<StaffCreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _occupation = TextEditingController();
  final _notes = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  var _autoPassword = true;
  var _obscurePassword = true;
  var _submitting = false;
  String? _error;
  DateTime _joinedOn = DateTime.now();
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
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
      _photoBytes = bytes;
      _photoName = file.name;
      _photoPath = file.path;
    });
  }

  void _clearPhoto() {
    setState(() {
      _photoBytes = null;
      _photoName = null;
      _photoPath = null;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _occupation.dispose();
    _notes.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  String get _initial {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return 'B';
    }
    return name.characters.first.toUpperCase();
  }

  Future<void> _pickJoinedOn() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedOn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.magenta,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _joinedOn = picked);
    }
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
      final password = _autoPassword ? null : _password.text.trim();
      final api = ref.read(staffApiProvider);
      var result = await api.createMember(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        occupation: _occupation.text.trim(),
        notes: _notes.text.trim(),
        joinedOn: DateFormat('yyyy-MM-dd').format(_joinedOn),
        password: password,
        passwordConfirmation:
            password == null ? null : _passwordConfirm.text.trim(),
      );

      if (_photoBytes != null) {
        final updated = await api.uploadMemberPhoto(
          result.member.id,
          bytes: _photoBytes,
          filePath: _photoPath,
          filename: _photoName ?? 'photo.jpg',
        );
        result = (member: updated, temporaryPassword: result.temporaryPassword);
      }

      ref.invalidate(staffMembersProvider);
      if (!mounted) {
        return;
      }
      final temp = result.temporaryPassword;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _SuccessSheet(
          name: result.member.name,
          memberId: result.member.memberId ?? '—',
          email: result.member.email,
          temporaryPassword: temp,
        ),
      );
      if (mounted) {
        context.go('/staff/members/${result.member.id}');
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
    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                    children: [
                      FadeRise(
                        child: ScreenHeader(
                          title: 'Add member',
                          subtitle: 'Creates login access and a unique member ID',
                          leading: const ScreenBackButton(
                            fallback: '/staff/members',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeRise(
                        delay: const Duration(milliseconds: 60),
                        child: _PreviewBanner(
                          initial: _initial,
                          name: _name.text.trim().isEmpty
                              ? 'New member'
                              : _name.text.trim(),
                          email: _email.text.trim().isEmpty
                              ? 'Email will appear here'
                              : _email.text.trim(),
                          photoBytes: _photoBytes,
                          onAddPhoto: _pickPhoto,
                          onRemovePhoto:
                              _photoBytes != null ? _clearPhoto : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeRise(
                        delay: const Duration(milliseconds: 100),
                        child: const SectionLabel('Identity'),
                      ),
                      const SizedBox(height: 8),
                      FadeRise(
                        delay: const Duration(milliseconds: 120),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  hintText: 'e.g. Ayesha Rahman',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _occupation,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Occupation',
                                  hintText: 'Optional',
                                  prefixIcon:
                                      Icon(Icons.work_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _pickJoinedOn,
                                borderRadius: BorderRadius.circular(16),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Joined on',
                                    prefixIcon:
                                        Icon(Icons.event_outlined),
                                    suffixIcon: Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat('dd MMM yyyy').format(_joinedOn),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeRise(
                        delay: const Duration(milliseconds: 160),
                        child: const SectionLabel('Contact'),
                      ),
                      const SizedBox(height: 8),
                      FadeRise(
                        delay: const Duration(milliseconds: 180),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'member@email.com',
                                  prefixIcon:
                                      Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                  hintText: 'Optional',
                                  prefixIcon:
                                      Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _address,
                                maxLines: 2,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  hintText: 'Optional',
                                  prefixIcon: Icon(Icons.home_outlined),
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeRise(
                        delay: const Duration(milliseconds: 220),
                        child: const SectionLabel('Login access'),
                      ),
                      const SizedBox(height: 8),
                      FadeRise(
                        delay: const Duration(milliseconds: 240),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _AccessToggle(
                                autoPassword: _autoPassword,
                                onChanged: (value) {
                                  setState(() {
                                    _autoPassword = value;
                                    _error = null;
                                  });
                                },
                              ),
                              if (!_autoPassword) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'At least 8 characters',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (_autoPassword) {
                                      return null;
                                    }
                                    if (v == null || v.length < 8) {
                                      return 'Use at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordConfirm,
                                  obscureText: _obscurePassword,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirm password',
                                    prefixIcon:
                                        Icon(Icons.lock_outline_rounded),
                                  ),
                                  validator: (v) {
                                    if (_autoPassword) {
                                      return null;
                                    }
                                    if (v != _password.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                const SizedBox(height: 10),
                                Text(
                                  'We’ll generate a temporary password. You’ll see it once so you can share it securely.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeRise(
                        delay: const Duration(milliseconds: 280),
                        child: const SectionLabel('Staff notes'),
                      ),
                      const SizedBox(height: 8),
                      FadeRise(
                        delay: const Duration(milliseconds: 300),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: TextFormField(
                            controller: _notes,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Internal notes',
                              hintText: 'Only visible to staff',
                              prefixIcon: Icon(Icons.notes_rounded),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.fieldBorder.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  child: GradientButton(
                    label: _submitting ? 'Creating…' : 'Create member',
                    icon: Icons.person_add_alt_1_rounded,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({
    required this.initial,
    required this.name,
    required this.email,
    required this.onAddPhoto,
    this.photoBytes,
    this.onRemovePhoto,
  });

  final String initial;
  final String name;
  final String email;
  final Uint8List? photoBytes;
  final VoidCallback onAddPhoto;
  final VoidCallback? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      gradient: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              PressableScale(
                onTap: onAddPhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: photoBytes == null
                            ? AppColors.brandDiagonal
                            : null,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        image: photoBytes != null
                            ? DecorationImage(
                                image: MemoryImage(photoBytes!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: photoBytes == null
                          ? Text(
                              initial,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
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
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      photoBytes == null
                          ? 'Tap photo to add a picture'
                          : 'Photo ready · will upload on create',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.magenta,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAddPhoto,
                  icon: Icon(
                    photoBytes == null
                        ? Icons.add_a_photo_outlined
                        : Icons.photo_library_outlined,
                    size: 18,
                  ),
                  label: Text(photoBytes == null ? 'Add photo' : 'Change photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: AppColors.fieldBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (onRemovePhoto != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: onRemovePhoto,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AccessToggle extends StatelessWidget {
  const _AccessToggle({
    required this.autoPassword,
    required this.onChanged,
  });

  final bool autoPassword;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Auto password',
              selected: autoPassword,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Set myself',
              selected: !autoPassword,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: selected ? AppColors.navy : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.name,
    required this.memberId,
    required this.email,
    required this.temporaryPassword,
  });

  final String name;
  final String memberId;
  final String email;
  final String? temporaryPassword;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Member created',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$name · $memberId',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          if (temporaryPassword != null && temporaryPassword!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TEMPORARY PASSWORD',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.magenta,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    temporaryPassword!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share securely, then ask them to change it after first login.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: temporaryPassword!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: AppColors.fieldBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          GradientButton(
            label: 'Open member profile',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

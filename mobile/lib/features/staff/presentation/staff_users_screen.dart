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

class StaffUsersScreen extends ConsumerStatefulWidget {
  const StaffUsersScreen({super.key});

  @override
  ConsumerState<StaffUsersScreen> createState() => _StaffUsersScreenState();
}

class _StaffUsersScreenState extends ConsumerState<StaffUsersScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = 'admin';
  var _saving = false;
  var _formOpen = false;
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await ref.read(staffApiProvider).listStaffUsers();
      if (mounted) {
        setState(() => _users = users);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppFormat.friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _create() async {
    if (_saving) {
      return;
    }
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Name and email are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref.read(staffApiProvider).createStaffUser(
            name: _name.text.trim(),
            email: _email.text.trim(),
            role: _role,
          );
      _name.clear();
      _email.clear();
      await _load();
      if (!mounted) {
        return;
      }
      setState(() => _formOpen = false);
      HapticFeedback.lightImpact();
      final temp = result.temporaryPassword;
      if (temp != null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Staff created',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share this temporary password securely. It won’t be shown again.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  temp,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: temp)),
                child: const Text('Copy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                child: const Text('Done'),
              ),
            ],
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
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: !_formOpen
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _formOpen = true),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                'Add staff',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
              children: [
                ScreenHeader(
                  title: 'Staff accounts',
                  subtitle:
                      '${_users.length} account${_users.length == 1 ? '' : 's'} · Super Admin only',
                  leading: const ScreenBackButton(),
                ),
                if (_formOpen) ...[
                  FadeRise(
                    child: SectionCard(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text(
                                'New staff user',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () =>
                                    setState(() => _formOpen = false),
                                icon: const Icon(Icons.close_rounded),
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Role',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppFilterChip(
                                  label: 'Admin',
                                  selected: _role == 'admin',
                                  expanded: true,
                                  onTap: () => setState(() => _role = 'admin'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppFilterChip(
                                  label: 'Accountant',
                                  selected: _role == 'accountant',
                                  expanded: true,
                                  onTap: () =>
                                      setState(() => _role = 'accountant'),
                                ),
                              ),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            AppErrorBanner(_error!),
                          ],
                          const SizedBox(height: 14),
                          GradientButton(
                            label: _saving ? 'Creating…' : 'Create staff user',
                            icon: Icons.check_rounded,
                            isLoading: _saving,
                            onPressed: _saving ? null : _create,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                FadeRise(
                  delay: const Duration(milliseconds: 50),
                  child: const SectionLabel('Team'),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.magenta),
                    ),
                  )
                else if (_users.isEmpty)
                  const AppEmptyCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'No staff listed',
                    detail: 'Create an Admin or Accountant account above.',
                  )
                else
                  ..._users.asMap().entries.map((entry) {
                    final i = entry.key;
                    final u = entry.value;
                    final name = '${u['name'] ?? ''}';
                    return FadeRise(
                      delay: Duration(milliseconds: 70 + (i.clamp(0, 8) * 28)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandDiagonal,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'S',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navy,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${u['email']}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip('${u['role']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

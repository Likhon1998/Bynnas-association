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
import 'staff_controllers.dart';

class StaffBackupScreen extends ConsumerStatefulWidget {
  const StaffBackupScreen({super.key});

  @override
  ConsumerState<StaffBackupScreen> createState() => _StaffBackupScreenState();
}

class _StaffBackupScreenState extends ConsumerState<StaffBackupScreen> {
  var _busy = false;
  String? _message;
  String? _error;
  String? _path;
  String? _size;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Create backup now?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'A snapshot will be written under storage/app/backups on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Backup'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _message = null;
      _path = null;
      _size = null;
    });
    try {
      final result = await ref.read(staffApiProvider).createBackup();
      final data = result['data'] as Map<String, dynamic>? ?? {};
      HapticFeedback.mediumImpact();
      setState(() {
        _path = '${data['path'] ?? ''}';
        _size = '${data['size_bytes'] ?? 0}';
        _message = 'Backup completed successfully';
      });
    } catch (error) {
      setState(() {
        _error = error is AppException
            ? error.message
            : AppFormat.friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _prettySize(String? raw) {
    final bytes = int.tryParse(raw ?? '') ?? 0;
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
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
                title: 'Database backup',
                subtitle: 'Protect association data before major changes',
                leading: ScreenBackButton(),
              ),
              FadeRise(
                child: SectionCard(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.backup_rounded,
                          color: AppColors.navy,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'On-demand snapshot',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Creates a file under storage/app/backups. For regular copies, schedule php artisan bynnas:backup-database on the server.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 14),
                        AppSuccessBanner(_message!),
                      ],
                      if (_path != null && _path!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          decoration: BoxDecoration(
                            color: AppColors.mist.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Path',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                _path!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Size  ${_prettySize(_size)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        AppErrorBanner(_error!),
                      ],
                      const SizedBox(height: 18),
                      GradientButton(
                        label: _busy ? 'Backing up…' : 'Create backup now',
                        icon: Icons.shield_moon_outlined,
                        isLoading: _busy,
                        onPressed: _busy ? null : _run,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

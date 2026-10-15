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

class StaffSmsScreen extends ConsumerStatefulWidget {
  const StaffSmsScreen({super.key});

  @override
  ConsumerState<StaffSmsScreen> createState() => _StaffSmsScreenState();
}

class _StaffSmsScreenState extends ConsumerState<StaffSmsScreen> {
  final _body = TextEditingController();
  var _sending = false;
  var _loading = true;
  String? _error;
  List<Map<String, dynamic>> _history = const [];

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
    _loadHistory();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(staffApiProvider).listSms();
      if (mounted) {
        setState(() => _history = items);
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

  Future<void> _send() async {
    if (_body.text.trim().isEmpty || _sending) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Send SMS broadcast?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This will queue the message to all eligible members.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(staffApiProvider).sendSms(body: _body.text.trim());
      _body.clear();
      await _loadHistory();
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS broadcast processed'),
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
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chars = _body.text.trim().length;

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.magenta,
            onRefresh: _loadHistory,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                const ScreenHeader(
                  title: 'SMS broadcast',
                  subtitle: 'Message members through the configured gateway',
                  leading: ScreenBackButton(),
                ),
                FadeRise(
                  child: SectionCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Compose',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _body,
                          maxLines: 5,
                          maxLength: 480,
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            alignLabelWithHint: true,
                            hintText: 'Write a clear, short SMS…',
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$chars characters',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          AppErrorBanner(_error!),
                        ],
                        const SizedBox(height: 12),
                        GradientButton(
                          label: _sending ? 'Sending…' : 'Send to all members',
                          icon: Icons.sms_rounded,
                          isLoading: _sending,
                          onPressed:
                              _sending || chars == 0 ? null : _send,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FadeRise(
                  delay: const Duration(milliseconds: 60),
                  child: const SectionLabel('Delivery history'),
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
                else if (_history.isEmpty)
                  const AppEmptyCard(
                    icon: Icons.sms_outlined,
                    title: 'No campaigns yet',
                    detail: 'Sent broadcasts will appear here with delivery counts.',
                  )
                else
                  ..._history.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return FadeRise(
                      delay: Duration(milliseconds: 80 + (i.clamp(0, 8) * 28)),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: SectionCard(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item['body']}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusChip('${item['status']}'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Recipients ${item['recipient_count']} · Sent ${item['sent_count'] ?? '—'} · Failed ${item['failed_count'] ?? '—'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

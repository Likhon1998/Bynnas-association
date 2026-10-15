import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../members/domain/member.dart';
import 'staff_controllers.dart';

final staffMemberDetailProvider = FutureProvider.autoDispose.family<
    ({
      Member member,
      Map<String, dynamic> balance,
      List<Map<String, dynamic>> payments,
    }),
    int>((ref, id) async {
  final api = ref.watch(staffApiProvider);
  final member = await api.memberDetail(id);
  final balance = await api.memberBalance(id);
  final payments = await api.memberPayments(id);
  return (member: member, balance: balance, payments: payments);
});

class StaffMemberDetailScreen extends ConsumerStatefulWidget {
  const StaffMemberDetailScreen({super.key, required this.memberId});

  final int memberId;

  @override
  ConsumerState<StaffMemberDetailScreen> createState() =>
      _StaffMemberDetailScreenState();
}

class _StaffMemberDetailScreenState
    extends ConsumerState<StaffMemberDetailScreen> {
  var _busy = false;
  var _uploadingPhoto = false;

  Future<void> _toggleActive(bool currentlyActive) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          currentlyActive ? 'Deactivate member?' : 'Reactivate member?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          currentlyActive
              ? 'They will not be able to sign in until reactivated.'
              : 'They will regain app access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  currentlyActive ? AppColors.danger : AppColors.navy,
            ),
            child: Text(currentlyActive ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );
    if (confirm != true || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(staffApiProvider);
      if (currentlyActive) {
        await api.deactivateMember(widget.memberId);
      } else {
        await api.reactivateMember(widget.memberId);
      }
      ref.invalidate(staffMemberDetailProvider(widget.memberId));
      ref.invalidate(staffMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyActive ? 'Member deactivated' : 'Member reactivated',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException
                  ? error.message
                  : AppFormat.friendlyError(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _updatePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await file.readAsBytes();
      await ref.read(staffApiProvider).uploadMemberPhoto(
            widget.memberId,
            bytes: bytes,
            filePath: file.path,
            filename: file.name,
          );
      ref.invalidate(staffMemberDetailProvider(widget.memberId));
      ref.invalidate(staffMembersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException
                  ? error.message
                  : AppFormat.friendlyError(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffMemberDetailProvider(widget.memberId));
    final canManage =
        ref.watch(authControllerProvider).asData?.value?.canManageMembers ??
            false;

    return Scaffold(
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              FadeRise(
                child: ScreenHeader(
                  title: 'Member profile',
                  subtitle: 'Details, balance, and payment history',
                  leading: const ScreenBackButton(fallback: '/staff/members'),
                  actions: [
                    if (canManage)
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => context.push(
                          '/staff/members/${widget.memberId}/edit',
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.navy,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.fieldBorder),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: state.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.magenta),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppFormat.friendlyError(error),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              staffMemberDetailProvider(widget.memberId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (data) => Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                    color: AppColors.magenta,
                    onRefresh: () async {
                      ref.invalidate(
                        staffMemberDetailProvider(widget.memberId),
                      );
                      await ref.read(
                        staffMemberDetailProvider(widget.memberId).future,
                      );
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                      children: [
                        FadeRise(
                          child: _ProfileHero(
                            member: data.member,
                            uploading: _uploadingPhoto,
                            onPhotoTap: canManage ? _updatePhoto : null,
                            onCopyId: () {
                              final id = data.member.memberId;
                              if (id == null || id.isEmpty) {
                                return;
                              }
                              Clipboard.setData(ClipboardData(text: id));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Member ID copied'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeRise(
                          delay: const Duration(milliseconds: 60),
                          child: _QuickActions(
                            member: data.member,
                            canManage: canManage,
                            onEdit: () => context.push(
                              '/staff/members/${widget.memberId}/edit',
                            ),
                            onPay: () => context.push(
                              '/staff/payments/record?memberId=${widget.memberId}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeRise(
                          delay: const Duration(milliseconds: 80),
                          child: _InfoGrid(member: data.member),
                        ),
                        if (data.member.notes != null &&
                            data.member.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          FadeRise(
                            delay: const Duration(milliseconds: 110),
                            child: SectionCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionLabel('Staff notes'),
                                  const SizedBox(height: 8),
                                  Text(
                                    data.member.notes!,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.navy,
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FadeRise(
                          delay: const Duration(milliseconds: 140),
                          child: const SectionLabel('Balance'),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 160),
                          child: Row(
                            children: [
                              Expanded(
                                child: MetricTile(
                                  label: 'Expected',
                                  value: AppFormat.money(
                                    data.balance['total_due'],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: MetricTile(
                                  label: 'Paid',
                                  value: AppFormat.money(
                                    data.balance['total_allocated'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeRise(
                          delay: const Duration(milliseconds: 180),
                          child: MetricTile(
                            label: 'Outstanding',
                            value: AppFormat.money(
                              data.balance['outstanding'],
                            ),
                            emphasis: true,
                          ),
                        ),
                        const SizedBox(height: 18),
                        FadeRise(
                          delay: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              const Expanded(
                                child: SectionLabel('Payment history'),
                              ),
                              Text(
                                '${data.payments.length}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (data.payments.isEmpty)
                          FadeRise(
                            delay: const Duration(milliseconds: 220),
                            child: SectionCard(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                'No payments recorded yet.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ...data.payments.asMap().entries.map((entry) {
                            final i = entry.key;
                            final p = entry.value;
                            final id = (p['id'] as num?)?.toInt();
                            final recorded = p['recorded_by_user'];
                            return FadeRise(
                              delay: Duration(milliseconds: 220 + (i * 35)),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SectionCard(
                                  onTap: id == null
                                      ? null
                                      : () => context
                                          .push('/finance/payments/$id'),
                                  padding: const EdgeInsets.all(13),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppColors.mist,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          color: AppColors.navy,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${p['receipt_number'] ?? 'Receipt'}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                                color: AppColors.navy,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${AppFormat.dateTime(p['received_at'])} · by ${recorded is Map ? recorded['name'] : '—'}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 11.5,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppFormat.money(p['amount']),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        if (canManage) ...[
                          const SizedBox(height: 14),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _toggleActive(data.member.isActive),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: data.member.isActive
                                  ? AppColors.danger
                                  : AppColors.navy,
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color: data.member.isActive
                                    ? AppColors.danger.withValues(alpha: 0.45)
                                    : AppColors.fieldBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              data.member.isActive
                                  ? 'Deactivate member'
                                  : 'Reactivate member',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.fieldBorder.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        child: GradientButton(
                          label: 'Record payment',
                          icon: Icons.add_card_outlined,
                          onPressed: () => context.push(
                            '/staff/payments/record?memberId=${widget.memberId}',
                          ),
                        ),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.member,
    required this.canManage,
    required this.onEdit,
    required this.onPay,
  });

  final Member member;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onPay;

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = member.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.add_card_outlined,
            label: 'Pay',
            color: AppColors.magenta,
            onTap: onPay,
          ),
        ),
        if (canManage) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              color: AppColors.navy,
              onTap: onEdit,
            ),
          ),
        ],
        if (hasPhone) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionTile(
              icon: Icons.phone_outlined,
              label: 'Call',
              color: AppColors.success,
              onTap: () => _launch(Uri(scheme: 'tel', path: phone)),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(
          child: _ActionTile(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            color: AppColors.blue,
            onTap: () => _launch(Uri(
              scheme: 'mailto',
              path: member.email,
            )),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.member,
    required this.uploading,
    required this.onPhotoTap,
    this.onCopyId,
  });

  final Member member;
  final bool uploading;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onCopyId;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      gradient: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PressableScale(
            onTap: onPhotoTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient:
                        member.photoUrl == null ? AppColors.brandDiagonal : null,
                    image: member.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(member.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.magenta.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: uploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : member.photoUrl == null
                          ? Text(
                              member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                            )
                          : null,
                ),
                if (onPhotoTap != null)
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.navy,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    StatusChip(member.isActive ? 'active' : 'inactive'),
                  ],
                ),
                const SizedBox(height: 4),
                PressableScale(
                  onTap: onCopyId,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.memberId ?? 'No member ID',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.magenta,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (member.memberId != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: AppColors.magenta.withValues(alpha: 0.8),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onPhotoTap != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    uploading ? 'Uploading photo…' : 'Tap photo to update',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final rows = <({IconData icon, String label, String value})>[
      (icon: Icons.mail_outline_rounded, label: 'Email', value: member.email),
      (
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: member.phone?.isNotEmpty == true ? member.phone! : 'Not on file',
      ),
      (
        icon: Icons.work_outline_rounded,
        label: 'Occupation',
        value: member.occupation?.isNotEmpty == true
            ? member.occupation!
            : 'Not set',
      ),
      (
        icon: Icons.home_outlined,
        label: 'Address',
        value: member.address?.isNotEmpty == true
            ? member.address!
            : 'Not on file',
      ),
      if (member.joinedOn != null)
        (
          icon: Icons.event_outlined,
          label: 'Joined',
          value: AppFormat.date(member.joinedOn),
        ),
    ];

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.fieldBorder.withValues(alpha: 0.7),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rows[i].icon, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 88,
                    child: Text(
                      rows[i].label,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

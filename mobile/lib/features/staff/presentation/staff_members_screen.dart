import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../members/domain/member.dart';
import 'staff_controllers.dart';

enum _MemberFilter { all, active, inactive }

class StaffMembersScreen extends ConsumerStatefulWidget {
  const StaffMembersScreen({super.key});

  @override
  ConsumerState<StaffMembersScreen> createState() => _StaffMembersScreenState();
}

class _StaffMembersScreenState extends ConsumerState<StaffMembersScreen> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  var _filter = _MemberFilter.all;
  var _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  String? get _statusParam => switch (_filter) {
        _MemberFilter.all => null,
        _MemberFilter.active => 'active',
        _MemberFilter.inactive => 'inactive',
      };

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(staffMembersProvider.notifier).search(
            value.trim(),
            status: _statusParam ?? '',
            silent: true,
          );
    });
  }

  Future<void> _setFilter(_MemberFilter filter) async {
    setState(() => _filter = filter);
    await ref.read(staffMembersProvider.notifier).setStatus(
          filter == _MemberFilter.all ? null : _statusParam,
        );
  }

  void _clearSearch() {
    _search.clear();
    setState(() => _query = '');
    ref.read(staffMembersProvider.notifier).search(
          null,
          status: _statusParam ?? '',
          silent: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(staffMembersProvider);
    final canAdd =
        ref.watch(authControllerProvider).asData?.value?.canManageMembers ??
            false;
    final count = members.asData?.value.length;

    return Scaffold(
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/staff/members/create'),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                'Add member',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                title: 'Members',
                subtitle: count == null
                    ? 'Find someone quickly, then open their profile'
                    : '$count member${count == 1 ? '' : 's'} shown',
                leading: context.canPop()
                    ? const ScreenBackButton()
                    : const SizedBox(width: 8),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.fieldBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Type a name, email, or member ID',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      ref.read(staffMembersProvider.notifier).search(
                            value.trim(),
                            status: _statusParam ?? '',
                            silent: true,
                          );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _MemberFilter.all,
                      onTap: () => _setFilter(_MemberFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      selected: _filter == _MemberFilter.active,
                      onTap: () => _setFilter(_MemberFilter.active),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Inactive',
                      selected: _filter == _MemberFilter.inactive,
                      onTap: () => _setFilter(_MemberFilter.inactive),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: AsyncBody(
                  value: members,
                  onRetry: () =>
                      ref.read(staffMembersProvider.notifier).refresh(),
                  emptyTitle: _query.isNotEmpty
                      ? 'No matches for “$_query”'
                      : 'No members yet',
                  emptyDetail: _query.isNotEmpty
                      ? 'Check the spelling, or switch filter to All.'
                      : 'Add your first member to get started.',
                  isEmpty: (items) => items.isEmpty,
                  data: (items) => RefreshIndicator(
                    color: AppColors.magenta,
                    onRefresh: () =>
                        ref.read(staffMembersProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        return _MemberRow(
                          member: items[index],
                          onOpen: () => context.push(
                            '/staff/members/${items[index].id}',
                          ),
                          onPay: () => context.push(
                            '/staff/payments/record?memberId=${items[index].id}',
                          ),
                        );
                      },
                    ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: selected ? Colors.white : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.onOpen,
    required this.onPay,
  });

  final Member member;
  final VoidCallback onOpen;
  final VoidCallback onPay;

  Future<void> _call() async {
    final phone = member.phone?.trim();
    if (phone == null || phone.isEmpty) {
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = member.phone != null && member.phone!.trim().isNotEmpty;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: Column(
        children: [
          PressableScale(
            onTap: onOpen,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: member.photoUrl == null
                        ? AppColors.brandDiagonal
                        : null,
                    image: member.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(member.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: member.photoUrl == null
                      ? Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        member.memberId ?? 'ID pending',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.magenta,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        member.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasPhone ||
                          (member.occupation != null &&
                              member.occupation!.isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (hasPhone) member.phone!,
                            if (member.occupation != null &&
                                member.occupation!.isNotEmpty)
                              member.occupation!,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                StatusChip(member.isActive ? 'active' : 'inactive'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniAction(
                  icon: Icons.add_card_outlined,
                  label: 'Pay',
                  onTap: onPay,
                  emphasized: true,
                ),
              ),
              if (hasPhone) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniAction(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    onTap: _call,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        // Prevent parent card navigation double-fire
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: emphasized
              ? AppColors.magenta.withValues(alpha: 0.1)
              : AppColors.mist,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: emphasized ? AppColors.magenta : AppColors.navy,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: emphasized ? AppColors.magenta : AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

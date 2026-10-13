import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/async_body.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import 'staff_controllers.dart';

class StaffMembersScreen extends ConsumerStatefulWidget {
  const StaffMembersScreen({super.key});

  @override
  ConsumerState<StaffMembersScreen> createState() => _StaffMembersScreenState();
}

class _StaffMembersScreenState extends ConsumerState<StaffMembersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(staffMembersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/members/create'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add member'),
      ),
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Members',
                subtitle: 'Add, search, and manage members',
                leading: context.canPop()
                    ? const ScreenBackButton()
                    : const SizedBox(width: 8),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search name, email, member ID',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: () => ref
                          .read(staffMembersProvider.notifier)
                          .search(_search.text.trim()),
                    ),
                  ),
                  onSubmitted: (value) => ref
                      .read(staffMembersProvider.notifier)
                      .search(value.trim()),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: AsyncBody(
                  value: members,
                  onRetry: () =>
                      ref.read(staffMembersProvider.notifier).refresh(),
                  emptyTitle: 'No members found',
                  emptyDetail: 'Try a different search term.',
                  isEmpty: (items) => items.isEmpty,
                  data: (items) => RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () =>
                        ref.read(staffMembersProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = items[index];
                        return SectionCard(
                          onTap: () =>
                              context.push('/staff/members/${member.id}'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.mist,
                                foregroundColor: AppColors.navy,
                                child: Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${member.memberId ?? '—'} · ${member.email}',
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
                              StatusChip(
                                member.isActive ? 'active' : 'inactive',
                              ),
                            ],
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

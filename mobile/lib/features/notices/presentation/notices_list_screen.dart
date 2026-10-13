import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_format.dart';
import '../../../shared/widgets/brand_atmosphere.dart';
import '../../../shared/widgets/screen_back_button.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import 'notice_controllers.dart';

class NoticesListScreen extends ConsumerWidget {
  const NoticesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesListProvider);
    final isStaff =
        ref.watch(authControllerProvider).asData?.value?.isStaff ?? false;

    return Scaffold(
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/staff/notices/compose'),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Compose'),
            )
          : null,
      body: BrandAtmosphere(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Notices',
                subtitle: 'Updates from the association',
                leading: context.canPop()
                    ? const ScreenBackButton()
                    : const SizedBox(width: 8),
                actions: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                    color: AppColors.navy,
                  ),
                ],
              ),
              Expanded(
                child: notices.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (error, _) => _MessageState(
                    title: 'Could not load notices',
                    detail: AppFormat.friendlyError(error),
                    onRetry: () =>
                        ref.read(noticesListProvider.notifier).refresh(),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return _MessageState(
                        title: 'No notices yet',
                        detail: 'Association notices for you will appear here.',
                        onRetry: () =>
                            ref.read(noticesListProvider.notifier).refresh(),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: () =>
                          ref.read(noticesListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, isStaff ? 88 : 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notice = items[index];
                          return SectionCard(
                            onTap: () =>
                                context.push('/notices/${notice.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notice.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (isStaff) StatusChip(notice.status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notice.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.detail,
    required this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/notice_api.dart';
import '../data/notification_api.dart';
import '../domain/app_notification.dart';
import '../domain/notice.dart';

final noticeApiProvider = Provider<NoticeApi>((ref) {
  return NoticeApi(ref.watch(apiClientProvider));
});

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(apiClientProvider));
});

final noticesListProvider =
    AsyncNotifierProvider<NoticesListController, List<Notice>>(
  NoticesListController.new,
);

class NoticesListController extends AsyncNotifier<List<Notice>> {
  @override
  Future<List<Notice>> build() => ref.read(noticeApiProvider).list();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(noticeApiProvider).list());
  }
}

final noticeDetailProvider =
    FutureProvider.family<Notice, int>((ref, id) async {
  return ref.watch(noticeApiProvider).show(id);
});

final unreadCountProvider =
    AsyncNotifierProvider<UnreadCountController, int>(UnreadCountController.new);

class UnreadCountController extends AsyncNotifier<int> {
  @override
  Future<int> build() => ref.read(notificationApiProvider).unreadCount();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationApiProvider).unreadCount(),
    );
  }
}

final notificationsInboxProvider =
    AsyncNotifierProvider<NotificationsInboxController, List<AppNotification>>(
  NotificationsInboxController.new,
);

class NotificationsInboxController extends AsyncNotifier<List<AppNotification>> {
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  @override
  Future<List<AppNotification>> build() async {
    _page = 1;
    final page = await ref.read(notificationApiProvider).list(page: 1);
    _hasMore = page.hasMore;
    return page.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    _page = 1;
    state = await AsyncValue.guard(() async {
      final page = await ref.read(notificationApiProvider).list(page: 1);
      _hasMore = page.hasMore;
      return page.items;
    });
    await ref.read(unreadCountProvider.notifier).refresh();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    try {
      final next = _page + 1;
      final page = await ref.read(notificationApiProvider).list(page: next);
      _page = next;
      _hasMore = page.hasMore;
      final current = state.asData?.value ?? const <AppNotification>[];
      state = AsyncData([...current, ...page.items]);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> markRead(int id) async {
    final updated = await ref.read(notificationApiProvider).markRead(id);
    final current = state.asData?.value ?? const <AppNotification>[];
    state = AsyncData([
      for (final item in current)
        if (item.id == id) updated else item,
    ]);
    await ref.read(unreadCountProvider.notifier).refresh();
  }

  Future<void> markAllRead() async {
    await ref.read(notificationApiProvider).markAllRead();
    final current = state.asData?.value ?? const <AppNotification>[];
    state = AsyncData([
      for (final item in current) item.copyWith(isRead: true),
    ]);
    await ref.read(unreadCountProvider.notifier).refresh();
  }
}

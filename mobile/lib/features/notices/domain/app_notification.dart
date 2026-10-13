class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.noticeId,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final int? noticeId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    int? noticeId;
    if (data is Map<String, dynamic>) {
      final raw = data['notice_id'];
      if (raw is num) {
        noticeId = raw.toInt();
      }
    }

    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      noticeId: noticeId,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      noticeId: noticeId,
    );
  }
}

class PaginatedNotifications {
  const PaginatedNotifications({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AppNotification> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

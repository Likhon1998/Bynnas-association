class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    this.publishAt,
    this.expiresAt,
  });

  final int id;
  final String title;
  final String body;
  final String status;
  final DateTime? publishAt;
  final DateTime? expiresAt;

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? '',
      publishAt: _parseDate(json['publish_at']),
      expiresAt: _parseDate(json['expires_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

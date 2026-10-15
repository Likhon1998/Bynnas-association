import 'package:intl/intl.dart';

/// Display helpers for money and status labels (UI only — never recalculate money).
class AppFormat {
  const AppFormat._();

  static String money(Object? value, {String currency = 'BDT'}) {
    final raw = value?.toString().trim() ?? '0.00';
    final normalized = raw.contains('.') ? raw : '$raw.00';
    return '৳ $normalized';
  }

  /// Formats API dates (`yyyy-MM-dd` or ISO) for display. Returns `—` if empty/invalid.
  static String date(Object? value, {String pattern = 'dd MMM yyyy'}) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    return DateFormat(pattern).format(parsed.toLocal());
  }

  static String dateTime(Object? value) {
    return date(value, pattern: 'dd MMM yyyy · HH:mm');
  }

  static String statusLabel(String? status) {
    if (status == null || status.isEmpty) {
      return 'Unknown';
    }
    return status
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  static String roleLabel(String? role) {
    return statusLabel(role);
  }

  static String friendlyError(Object error) {
    final text = error.toString();
    return text
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^AppException:\s*'), '')
        .replaceFirst(RegExp(r'^Bad state:\s*'), '')
        .trim();
  }
}

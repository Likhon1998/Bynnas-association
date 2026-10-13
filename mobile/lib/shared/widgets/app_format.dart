/// Display helpers for money and status labels (UI only — never recalculate money).
class AppFormat {
  const AppFormat._();

  static String money(Object? value, {String currency = 'BDT'}) {
    final raw = value?.toString().trim() ?? '0.00';
    final normalized = raw.contains('.') ? raw : '$raw.00';
    return '৳ $normalized';
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

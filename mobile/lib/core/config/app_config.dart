import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  /// Override with `--dart-define=API_BASE_URL=https://host/api/v1`
  ///
  /// Defaults:
  /// - Web / desktop: `http://127.0.0.1:8765/api/v1`
  /// - Android emulator: `http://10.0.2.2:8765/api/v1` (host loopback)
  /// - iOS simulator: `http://127.0.0.1:8765/api/v1`
  /// - Physical devices: pass LAN IP via dart-define (do not hardcode).
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/')
          ? fromEnv.substring(0, fromEnv.length - 1)
          : fromEnv;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8765/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8765/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:8765/api/v1';
    }
  }

  static const String appName = 'Bynnas Association';
}

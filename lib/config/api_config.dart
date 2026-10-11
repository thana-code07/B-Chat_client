import 'package:flutter/foundation.dart';

/// Local Express server. Android emulator reaches the host through 10.0.2.2.
/// Debug builds allow that cleartext hop. Release builds must set
/// `--dart-define=API_BASE_URL=https://host`.
String apiBaseUrl() {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

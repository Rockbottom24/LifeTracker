import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get defaultAbsoluteBaseUrl => String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://192.168.29.63:8080/api/v1',
      );

  static String get defaultBaseUrl => kIsWeb ? '/api/v1' : defaultAbsoluteBaseUrl;
  static const String baseUrlKey = 'api_base_url';
  static const String accessTokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userDisplayNameKey = 'user_display_name';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static String normalizeBaseUrl(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }

    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }

  static bool isAbsoluteUrl(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith('http://') || normalized.startsWith('https://');
  }

  static String resolveBaseUrl(String? value) {
    final normalized = normalizeBaseUrl(value);

    if (kIsWeb) {
      return '/api/v1';
    }

    if (normalized.isEmpty) {
      return defaultAbsoluteBaseUrl;
    }

    if (isAbsoluteUrl(normalized)) {
      return normalized;
    }

    return defaultAbsoluteBaseUrl;
  }

  static bool shouldResetLegacyBaseUrl(String? value) {
    if (kIsWeb) return false;
    final normalized = normalizeBaseUrl(value);
    return normalized.contains('localhost') ||
        normalized.contains('127.0.0.1') ||
        normalized.contains('10.0.2.2') ||
        normalized.contains('192.168.29.63') ||
        !isAbsoluteUrl(normalized);
  }
}

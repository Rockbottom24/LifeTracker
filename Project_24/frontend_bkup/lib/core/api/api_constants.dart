class ApiConstants {
  static const String defaultBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static const String baseUrlKey = 'api_base_url';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static String normalizeBaseUrl(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return defaultBaseUrl;
    }

    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}

/// Provides default runtime configuration values for the GDMS app.
final class ApiDefaults {
  static const baseUrl = String.fromEnvironment(
    'GDMS_API_BASE_URL',
    defaultValue: 'http://localhost:5012',
  );

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }
}

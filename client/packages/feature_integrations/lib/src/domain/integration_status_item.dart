/// Represents one configured integration visible in the dashboard.
final class IntegrationStatusItem {
  const IntegrationStatusItem({
    required this.code,
    required this.displayName,
    required this.category,
    required this.status,
    required this.detail,
  });

  final String code;
  final String displayName;
  final String category;
  final String status;
  final String detail;
}

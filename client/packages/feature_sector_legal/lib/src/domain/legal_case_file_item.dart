/// Represents a recent case file shown in the legal dashboard.
final class LegalCaseFileItem {
  const LegalCaseFileItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
}

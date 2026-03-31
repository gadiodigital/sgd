/// Represents one legal matter or actionable legal item.
final class LegalMatterItem {
  const LegalMatterItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;
}

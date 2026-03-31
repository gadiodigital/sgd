/// Represents one corporate dossier, contract, or governance alert.
final class CorporateRecordItem {
  const CorporateRecordItem({
    this.id = '',
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String id;
  final String title;
  final String subtitle;
  final String status;
}

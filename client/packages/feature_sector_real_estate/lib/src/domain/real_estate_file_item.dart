/// Represents one real-estate dossier, contract, or compliance alert.
final class RealEstateFileItem {
  const RealEstateFileItem({
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

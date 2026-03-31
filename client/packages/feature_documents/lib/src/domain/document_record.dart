/// Represents a document row in the operational dashboard.
final class DocumentRecord {
  const DocumentRecord({
    required this.id,
    required this.title,
    required this.typeLabel,
    required this.classificationLabel,
    required this.statusLabel,
    required this.ownerLabel,
    required this.updatedAtLabel,
    required this.onLegalHold,
  });

  final String id;
  final String title;
  final String typeLabel;
  final String classificationLabel;
  final String statusLabel;
  final String ownerLabel;
  final String updatedAtLabel;
  final bool onLegalHold;
}

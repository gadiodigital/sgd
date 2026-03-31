/// Represents a document linked to a case file.
final class CaseFileDocumentReference {
  factory CaseFileDocumentReference.fromJson(Map<String, dynamic> json) {
    return CaseFileDocumentReference(
      documentId: json['documentId'] as String? ?? '',
      title: json['documentTitle'] as String? ?? 'Documento',
      documentTypeCode: json['documentTypeCode'] as String? ?? 'GENERAL',
      status: json['documentStatus'] as String? ?? 'ACTIVE',
      linkedAtUtc: DateTime.tryParse(json['linkedAtUtc'] as String? ?? ''),
    );
  }

  const CaseFileDocumentReference({
    required this.documentId,
    required this.title,
    required this.documentTypeCode,
    required this.status,
    required this.linkedAtUtc,
  });

  final String documentId;
  final String title;
  final String documentTypeCode;
  final String status;
  final DateTime? linkedAtUtc;
}

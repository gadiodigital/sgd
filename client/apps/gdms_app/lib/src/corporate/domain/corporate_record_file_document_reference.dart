/// Represents one document linked to a corporate record file.
final class CorporateRecordFileDocumentReference {
  const CorporateRecordFileDocumentReference({
    required this.documentId,
    required this.title,
    required this.documentTypeCode,
    required this.status,
    required this.linkedAtUtc,
  });

  factory CorporateRecordFileDocumentReference.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawLinkedAt = json['linkedAtUtc'] as String?;
    return CorporateRecordFileDocumentReference(
      documentId: json['documentId'] as String? ?? '',
      title: json['documentTitle'] as String? ?? 'Documento',
      documentTypeCode: json['documentTypeCode'] as String? ?? 'SIN_TIPO',
      status: json['documentStatus'] as String? ?? 'ACTIVE',
      linkedAtUtc: rawLinkedAt == null ? null : DateTime.tryParse(rawLinkedAt),
    );
  }

  final String documentId;
  final String title;
  final String documentTypeCode;
  final String status;
  final DateTime? linkedAtUtc;
}

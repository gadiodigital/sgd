final class ContainerDocumentEntry {
  const ContainerDocumentEntry({
    required this.documentId,
    required this.documentTitle,
    required this.documentTypeCode,
    required this.documentStatus,
  });

  factory ContainerDocumentEntry.fromJson(Map<String, dynamic> json) {
    return ContainerDocumentEntry(
      documentId: json['documentId'] as String,
      documentTitle: json['documentTitle'] as String,
      documentTypeCode: json['documentTypeCode'] as String,
      documentStatus: json['documentStatus'] as String,
    );
  }

  final String documentId;
  final String documentTitle;
  final String documentTypeCode;
  final String documentStatus;
}

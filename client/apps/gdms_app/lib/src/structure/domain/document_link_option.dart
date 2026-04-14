final class DocumentLinkOption {
  const DocumentLinkOption({
    required this.id,
    required this.title,
    required this.documentTypeCode,
    required this.status,
  });

  factory DocumentLinkOption.fromJson(Map<String, dynamic> json) {
    return DocumentLinkOption(
      id: json['id'] as String,
      title: json['title'] as String,
      documentTypeCode: json['documentTypeCode'] as String,
      status: json['status'] as String,
    );
  }

  final String id;
  final String title;
  final String documentTypeCode;
  final String status;
}

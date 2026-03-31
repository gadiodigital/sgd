/// Represents a case file available for document linking.
final class CaseFileReference {
  factory CaseFileReference.fromJson(Map<String, dynamic> json) {
    return CaseFileReference(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? 'SIN-CODIGO',
      title: json['title'] as String? ?? 'Expediente',
      category: json['category'] as String? ?? 'GENERAL',
      status: json['status'] as String? ?? 'OPEN',
    );
  }

  const CaseFileReference({
    required this.id,
    required this.code,
    required this.title,
    required this.category,
    required this.status,
  });

  final String id;
  final String code;
  final String title;
  final String category;
  final String status;
}

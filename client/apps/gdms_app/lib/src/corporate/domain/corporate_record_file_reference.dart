/// Represents one corporate record file available inside the organization.
final class CorporateRecordFileReference {
  const CorporateRecordFileReference({
    required this.id,
    required this.code,
    required this.title,
    required this.category,
    required this.ownerArea,
    required this.status,
  });

  factory CorporateRecordFileReference.fromJson(Map<String, dynamic> json) {
    return CorporateRecordFileReference(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? 'SIN-CODIGO',
      title: json['title'] as String? ?? 'Legajo',
      category: json['category'] as String? ?? 'GENERAL',
      ownerArea: json['ownerArea'] as String? ?? 'SIN_AREA',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  final String id;
  final String code;
  final String title;
  final String category;
  final String ownerArea;
  final String status;
}

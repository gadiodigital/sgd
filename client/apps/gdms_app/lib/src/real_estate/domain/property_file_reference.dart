/// Represents one property file available inside the tenant.
final class PropertyFileReference {
  const PropertyFileReference({
    required this.id,
    required this.code,
    required this.title,
    required this.address,
    required this.operationType,
    required this.status,
  });

  factory PropertyFileReference.fromJson(Map<String, dynamic> json) {
    return PropertyFileReference(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? 'SIN-CODIGO',
      title: json['title'] as String? ?? 'Legajo',
      address: json['address'] as String? ?? 'Sin dirección',
      operationType: json['operationType'] as String? ?? 'MIXED',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  final String id;
  final String code;
  final String title;
  final String address;
  final String operationType;
  final String status;
}

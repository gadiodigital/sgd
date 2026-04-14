final class StructureProjectEntry {
  const StructureProjectEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.status,
  });

  factory StructureProjectEntry.fromJson(Map<String, dynamic> json) {
    return StructureProjectEntry(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
    );
  }

  final String id;
  final String code;
  final String name;
  final String? description;
  final String status;
}

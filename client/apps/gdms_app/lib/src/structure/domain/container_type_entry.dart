final class ContainerTypeEntry {
  const ContainerTypeEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.iconKey,
    required this.isRootAllowed,
    required this.acceptsDocuments,
    required this.metadataSchema,
  });

  factory ContainerTypeEntry.fromJson(Map<String, dynamic> json) {
    return ContainerTypeEntry(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      iconKey: json['iconKey'] as String? ?? 'folder',
      isRootAllowed: json['isRootAllowed'] as bool? ?? false,
      acceptsDocuments: json['acceptsDocuments'] as bool? ?? false,
      metadataSchema: _toMap(json['metadataSchema']),
    );
  }

  final String id;
  final String code;
  final String name;
  final String iconKey;
  final bool isRootAllowed;
  final bool acceptsDocuments;
  final Map<String, Object?> metadataSchema;

  static Map<String, Object?> _toMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, Object?>.from(value);
    }
    return const <String, Object?>{};
  }
}

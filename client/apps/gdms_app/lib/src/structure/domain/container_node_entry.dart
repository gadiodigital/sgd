final class ContainerNodeEntry {
  const ContainerNodeEntry({
    required this.id,
    required this.containerTypeId,
    required this.parentContainerId,
    required this.code,
    required this.name,
    required this.metadata,
  });

  factory ContainerNodeEntry.fromJson(Map<String, dynamic> json) {
    return ContainerNodeEntry(
      id: json['id'] as String,
      containerTypeId: json['containerTypeId'] as String,
      parentContainerId: json['parentContainerId'] as String?,
      code: json['code'] as String,
      name: json['name'] as String,
      metadata: _toMap(json['metadata']),
    );
  }

  final String id;
  final String containerTypeId;
  final String? parentContainerId;
  final String code;
  final String name;
  final Map<String, Object?> metadata;

  static Map<String, Object?> _toMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, Object?>.from(value);
    }
    return const <String, Object?>{};
  }
}

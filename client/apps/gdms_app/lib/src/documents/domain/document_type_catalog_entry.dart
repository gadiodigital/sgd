import 'document_metadata_field.dart';

/// Represents a tenant-visible document type definition returned by the API.
final class DocumentTypeCatalogEntry {
  const DocumentTypeCatalogEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.sector,
    required this.isActive,
    required this.metadataFields,
    this.tenantId,
  });

  factory DocumentTypeCatalogEntry.fromJson(Map<String, dynamic> json) {
    final schemaMap = _toStringMap(json['metadataSchema']);
    final fields = schemaMap.entries
        .where((entry) => entry.value is Map || entry.value is Map<String, dynamic>)
        .map(
          (entry) => DocumentMetadataField.fromJson(
            entry.key,
            _toStringMap(entry.value),
          ),
        )
        .toList(growable: false);

    return DocumentTypeCatalogEntry(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String?,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sector: json['sector'] as String? ?? '',
      isActive: json['isActive'] == true,
      metadataFields: fields,
    );
  }

  final String id;
  final String? tenantId;
  final String code;
  final String name;
  final String sector;
  final bool isActive;
  final List<DocumentMetadataField> metadataFields;

  String get displayLabel => '$name ($code)';

  static Map<String, dynamic> _toStringMap(Object? rawValue) {
    if (rawValue is Map<String, dynamic>) {
      return rawValue;
    }

    if (rawValue is Map) {
      return rawValue.map(
        (key, value) => MapEntry('$key', value),
      );
    }

    return const <String, dynamic>{};
  }
}

class ScanDocumentTypeDefinition {
  const ScanDocumentTypeDefinition({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.attributes,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final List<ScanAttributeDefinition> attributes;
}

class ScanAttributeDefinition {
  const ScanAttributeDefinition({
    required this.id,
    required this.name,
    required this.code,
    required this.dataType,
    required this.extension,
    required this.regex,
    required this.options,
  });

  final String id;
  final String name;
  final String code;
  final String dataType;
  final String extension;
  final String regex;
  final List<ScanAttributeOption> options;
}

class ScanAttributeOption {
  const ScanAttributeOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;
}

class SavedNodeDocument {
  const SavedNodeDocument({
    required this.id,
    required this.title,
    required this.documentTypeName,
    required this.currentVersionNumber,
    required this.pageCount,
    required this.updatedAtLabel,
  });

  factory SavedNodeDocument.fromJson(Map<String, dynamic> json) => SavedNodeDocument(
        id: json['id'].toString(),
        title: (json['title'] ?? '').toString(),
        documentTypeName: (json['documentTypeName'] ?? '').toString(),
        currentVersionNumber: (json['currentVersionNumber'] as num?)?.toInt() ?? 1,
        pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
        updatedAtLabel: _formatUpdatedAt((json['updatedAt'] ?? '').toString()),
      );

  final String id;
  final String title;
  final String documentTypeName;
  final String updatedAtLabel;
  final int currentVersionNumber;
  final int pageCount;
}

String _formatUpdatedAt(String value) {
  if (value.trim().isEmpty) {
    return 'sin fecha';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

/// Enumerates the supported metadata field kinds emitted by the backend.
enum DocumentMetadataFieldType { text, date, integer, number, boolean }

/// Represents a metadata field rendered dynamically from the document type schema.
final class DocumentMetadataField {
  const DocumentMetadataField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.maxLength,
  });

  factory DocumentMetadataField.fromJson(
    String key,
    Map<String, dynamic> json,
  ) {
    return DocumentMetadataField(
      key: key,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : key,
      type: _parseType(json['type'] as String?),
      required: json['required'] == true,
      maxLength: json['maxLength'] is num
          ? (json['maxLength'] as num).toInt()
          : null,
    );
  }

  final String key;
  final String label;
  final DocumentMetadataFieldType type;
  final bool required;
  final int? maxLength;

  String? validateValue(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return required ? 'El campo $label es obligatorio.' : null;
    }

    if (type == DocumentMetadataFieldType.text &&
        maxLength != null &&
        value.length > maxLength!) {
      return 'El campo $label excede ${maxLength!} caracteres.';
    }

    if (type == DocumentMetadataFieldType.date &&
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return 'El campo $label debe usar formato AAAA-MM-DD.';
    }

    if (type == DocumentMetadataFieldType.integer &&
        int.tryParse(value) == null) {
      return 'El campo $label debe ser un entero.';
    }

    if (type == DocumentMetadataFieldType.number &&
        num.tryParse(value) == null) {
      return 'El campo $label debe ser numérico.';
    }

    if (type == DocumentMetadataFieldType.boolean &&
        value != 'true' &&
        value != 'false') {
      return 'El campo $label debe ser verdadero o falso.';
    }

    return null;
  }

  String get helperText {
    return switch (type) {
      DocumentMetadataFieldType.date => 'Formato AAAA-MM-DD',
      DocumentMetadataFieldType.integer => 'Valor entero',
      DocumentMetadataFieldType.number => 'Valor numérico',
      DocumentMetadataFieldType.boolean => 'Seleccione verdadero o falso',
      DocumentMetadataFieldType.text when maxLength != null =>
        'Máximo $maxLength caracteres',
      _ => '',
    };
  }

  static DocumentMetadataFieldType _parseType(String? rawType) {
    return switch (rawType?.trim().toLowerCase()) {
      'date' => DocumentMetadataFieldType.date,
      'integer' => DocumentMetadataFieldType.integer,
      'number' => DocumentMetadataFieldType.number,
      'boolean' => DocumentMetadataFieldType.boolean,
      _ => DocumentMetadataFieldType.text,
    };
  }
}

import 'dart:convert';

/// Enumerates the supported metadata field kinds emitted by the backend.
enum DocumentMetadataFieldType {
  text,
  date,
  integer,
  number,
  boolean,
  list,
  json,
}

/// Represents a metadata field rendered dynamically from the document type schema.
final class DocumentMetadataField {
  const DocumentMetadataField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.maxLength,
    this.options = const <String>[],
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
      options: json['options'] is List
          ? (json['options'] as List)
                .whereType<String>()
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
    );
  }

  final String key;
  final String label;
  final DocumentMetadataFieldType type;
  final bool required;
  final int? maxLength;
  final List<String> options;

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

    if (type == DocumentMetadataFieldType.list &&
        options.isNotEmpty &&
        !options.contains(value)) {
      return 'El campo $label debe usar una opción configurada.';
    }

    if (type == DocumentMetadataFieldType.json) {
      try {
        jsonDecode(value);
      } catch (_) {
        return 'El campo $label debe contener JSON válido.';
      }
    }

    return null;
  }

  String get helperText {
    return switch (type) {
      DocumentMetadataFieldType.date => 'Formato AAAA-MM-DD',
      DocumentMetadataFieldType.integer => 'Valor entero',
      DocumentMetadataFieldType.number => 'Valor numérico',
      DocumentMetadataFieldType.boolean => 'Seleccione verdadero o falso',
      DocumentMetadataFieldType.list => 'Seleccione una opción',
      DocumentMetadataFieldType.json => 'Objeto, lista o valor JSON válido',
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
      'decimal' => DocumentMetadataFieldType.number,
      'boolean' => DocumentMetadataFieldType.boolean,
      'list' => DocumentMetadataFieldType.list,
      'json' => DocumentMetadataFieldType.json,
      _ => DocumentMetadataFieldType.text,
    };
  }
}

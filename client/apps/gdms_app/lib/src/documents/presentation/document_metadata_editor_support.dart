import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/document_metadata_field.dart';

/// Holds reusable helper functions for document metadata editing state.
final class DocumentMetadataEditorSupport {
  const DocumentMetadataEditorSupport._();

  static Map<String, Object?> buildPayload(
    Iterable<DocumentMetadataField> fields,
    Map<String, TextEditingController> controllers,
    Map<String, String?> booleanValues,
  ) {
    final payload = <String, Object?>{};
    for (final field in fields) {
      if (field.type == DocumentMetadataFieldType.boolean) {
        final value = booleanValues[field.key];
        if (value != null && value.isNotEmpty) {
          payload[field.key] = value == 'true';
        }
        continue;
      }

      if (field.type == DocumentMetadataFieldType.list &&
          field.options.isNotEmpty) {
        final value = booleanValues[field.key];
        if (value != null && value.isNotEmpty) {
          payload[field.key] = value;
        }
        continue;
      }

      final text = controllers[field.key]?.text.trim() ?? '';
      if (text.isEmpty) {
        continue;
      }

      if (field.type == DocumentMetadataFieldType.json) {
        payload[field.key] = jsonDecode(text);
      } else {
        payload[field.key] = text;
      }
    }

    return payload;
  }

  static void syncEditors({
    required Iterable<DocumentMetadataField> fields,
    required Map<String, Object?> metadata,
    required Map<String, TextEditingController> controllers,
    required Map<String, String?> booleanValues,
  }) {
    for (final controller in controllers.values) {
      controller.dispose();
    }

    controllers.clear();
    booleanValues.clear();

    for (final field in fields) {
      final value = metadata[field.key];
      if (field.type == DocumentMetadataFieldType.boolean) {
        final normalizedValue = value?.toString();
        booleanValues[field.key] =
            normalizedValue == 'true' || normalizedValue == 'false'
            ? normalizedValue
            : null;
      } else if (field.type == DocumentMetadataFieldType.list &&
          field.options.isNotEmpty) {
        final normalizedValue = value == null ? null : '$value';
        booleanValues[field.key] =
            normalizedValue != null && field.options.contains(normalizedValue)
            ? normalizedValue
            : null;
      } else {
        controllers[field.key] = TextEditingController(
          text: value == null
              ? ''
              : field.type == DocumentMetadataFieldType.json
              ? jsonEncode(value)
              : '$value',
        );
      }
    }
  }
}

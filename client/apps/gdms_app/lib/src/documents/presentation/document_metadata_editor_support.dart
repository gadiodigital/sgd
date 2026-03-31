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

      final text = controllers[field.key]?.text.trim() ?? '';
      if (text.isNotEmpty) {
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
        booleanValues[field.key] = value is bool ? '$value' : null;
      } else {
        controllers[field.key] = TextEditingController(
          text: value == null ? '' : '$value',
        );
      }
    }
  }
}

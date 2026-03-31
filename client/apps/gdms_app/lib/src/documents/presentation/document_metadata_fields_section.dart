import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../domain/document_metadata_field.dart';

/// Renders the dynamic metadata form for the selected document type.
class DocumentMetadataFieldsSection extends StatelessWidget {
  const DocumentMetadataFieldsSection({
    required this.fields,
    required this.controllers,
    required this.booleanValues,
    required this.onBooleanChanged,
    super.key,
  });

  final List<DocumentMetadataField> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, String?> booleanValues;
  final void Function(String key, String? value) onBooleanChanged;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return GdmsSectionCard(
      title: 'Metadatos tipados',
      subtitle:
          'Los campos se validan según el esquema del tipo documental activo.',
      child: Column(
        children: fields.map(_buildField).toList(growable: false),
      ),
    );
  }

  Widget _buildField(DocumentMetadataField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: switch (field.type) {
        DocumentMetadataFieldType.boolean => DropdownButtonFormField<String>(
          key: ValueKey('${field.key}:${booleanValues[field.key]}'),
          initialValue: booleanValues[field.key],
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helperText,
          ),
          items: const [
            DropdownMenuItem<String>(value: 'true', child: Text('Verdadero')),
            DropdownMenuItem<String>(value: 'false', child: Text('Falso')),
          ],
          validator: field.validateValue,
          onChanged: (value) => onBooleanChanged(field.key, value),
        ),
        _ => TextFormField(
          controller: controllers[field.key],
          decoration: InputDecoration(
            labelText: field.label,
            helperText: field.helperText,
          ),
          keyboardType: _keyboardTypeFor(field.type),
          validator: field.validateValue,
          maxLength: field.maxLength,
        ),
      },
    );
  }

  TextInputType _keyboardTypeFor(DocumentMetadataFieldType type) {
    return switch (type) {
      DocumentMetadataFieldType.date => TextInputType.datetime,
      DocumentMetadataFieldType.integer => TextInputType.number,
      DocumentMetadataFieldType.number => const TextInputType.numberWithOptions(
        decimal: true,
      ),
      _ => TextInputType.text,
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/document_metadata_field.dart';
import 'package:gdms_app/src/documents/presentation/document_metadata_editor_support.dart';

void main() {
  const fields = <DocumentMetadataField>[
    DocumentMetadataField(
      key: 'notes',
      label: 'Notas',
      type: DocumentMetadataFieldType.text,
      required: false,
    ),
    DocumentMetadataField(
      key: 'issuedAt',
      label: 'Emitido',
      type: DocumentMetadataFieldType.date,
      required: false,
    ),
    DocumentMetadataField(
      key: 'isSigned',
      label: 'Firmado',
      type: DocumentMetadataFieldType.boolean,
      required: false,
    ),
  ];

  test('buildPayload normaliza texto y booleans', () {
    final controllers = <String, TextEditingController>{
      'notes': TextEditingController(text: '  contrato base  '),
      'issuedAt': TextEditingController(text: '2026-03-31'),
    };
    final booleanValues = <String, String?>{
      'isSigned': 'true',
    };

    final payload = DocumentMetadataEditorSupport.buildPayload(
      fields,
      controllers,
      booleanValues,
    );

    expect(payload, {
      'notes': 'contrato base',
      'issuedAt': '2026-03-31',
      'isSigned': true,
    });
  });

  test('buildPayload omite vacios y booleans sin valor', () {
    final controllers = <String, TextEditingController>{
      'notes': TextEditingController(text: '   '),
      'issuedAt': TextEditingController(text: ''),
    };
    final booleanValues = <String, String?>{
      'isSigned': null,
    };

    final payload = DocumentMetadataEditorSupport.buildPayload(
      fields,
      controllers,
      booleanValues,
    );

    expect(payload, isEmpty);
  });

  test('syncEditors repuebla controllers y valores booleanos desde metadata', () {
    final staleController = TextEditingController(text: 'old');
    final controllers = <String, TextEditingController>{
      'legacy': staleController,
    };
    final booleanValues = <String, String?>{
      'legacyFlag': 'false',
    };

    DocumentMetadataEditorSupport.syncEditors(
      fields: fields,
      metadata: const <String, Object?>{
        'notes': 'Contrato 2026',
        'issuedAt': '2026-03-31',
        'isSigned': false,
      },
      controllers: controllers,
      booleanValues: booleanValues,
    );

    expect(controllers.keys, {'notes', 'issuedAt'});
    expect(controllers['notes']!.text, 'Contrato 2026');
    expect(controllers['issuedAt']!.text, '2026-03-31');
    expect(booleanValues, {'isSigned': 'false'});
  });

  test('syncEditors con metadata vacia deja mapas limpios y defaults', () {
    final controllers = <String, TextEditingController>{
      'notes': TextEditingController(text: 'old'),
    };
    final booleanValues = <String, String?>{
      'isSigned': 'true',
    };

    DocumentMetadataEditorSupport.syncEditors(
      fields: fields,
      metadata: const <String, Object?>{},
      controllers: controllers,
      booleanValues: booleanValues,
    );

    expect(controllers.keys, {'notes', 'issuedAt'});
    expect(controllers['notes']!.text, isEmpty);
    expect(controllers['issuedAt']!.text, isEmpty);
    expect(booleanValues, {'isSigned': null});
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/document_metadata_field.dart';

void main() {
  test('fromJson normaliza label tipo required y maxLength', () {
    final field = DocumentMetadataField.fromJson('caseNumber', {
      'label': '  Numero de expediente  ',
      'type': 'integer',
      'required': true,
      'maxLength': 12,
    });

    expect(field.key, 'caseNumber');
    expect(field.label, 'Numero de expediente');
    expect(field.type, DocumentMetadataFieldType.integer);
    expect(field.required, isTrue);
    expect(field.maxLength, 12);
  });

  test('fromJson usa defaults seguros cuando faltan datos o tipo es invalido', () {
    final field = DocumentMetadataField.fromJson('fallbackKey', {
      'label': '   ',
      'type': 'custom',
      'required': false,
      'maxLength': 'bad',
    });

    expect(field.label, 'fallbackKey');
    expect(field.type, DocumentMetadataFieldType.text);
    expect(field.required, isFalse);
    expect(field.maxLength, isNull);
  });

  test('helperText cubre date integer number boolean text y fallback vacio', () {
    expect(
      const DocumentMetadataField(
        key: 'signedAt',
        label: 'Fecha',
        type: DocumentMetadataFieldType.date,
        required: false,
      ).helperText,
      'Formato AAAA-MM-DD',
    );
    expect(
      const DocumentMetadataField(
        key: 'folios',
        label: 'Folios',
        type: DocumentMetadataFieldType.integer,
        required: false,
      ).helperText,
      'Valor entero',
    );
    expect(
      const DocumentMetadataField(
        key: 'amount',
        label: 'Monto',
        type: DocumentMetadataFieldType.number,
        required: false,
      ).helperText,
      'Valor numérico',
    );
    expect(
      const DocumentMetadataField(
        key: 'approved',
        label: 'Aprobado',
        type: DocumentMetadataFieldType.boolean,
        required: false,
      ).helperText,
      'Seleccione verdadero o falso',
    );
    expect(
      const DocumentMetadataField(
        key: 'title',
        label: 'Titulo',
        type: DocumentMetadataFieldType.text,
        required: false,
        maxLength: 40,
      ).helperText,
      'Máximo 40 caracteres',
    );
    expect(
      const DocumentMetadataField(
        key: 'notes',
        label: 'Notas',
        type: DocumentMetadataFieldType.text,
        required: false,
      ).helperText,
      '',
    );
  });

  test('validateValue cubre required y validaciones por tipo', () {
    const requiredText = DocumentMetadataField(
      key: 'title',
      label: 'Titulo',
      type: DocumentMetadataFieldType.text,
      required: true,
      maxLength: 5,
    );
    expect(requiredText.validateValue('   '), 'El campo Titulo es obligatorio.');
    expect(
      requiredText.validateValue('demasiado'),
      'El campo Titulo excede 5 caracteres.',
    );
    expect(requiredText.validateValue('ok'), isNull);

    const dateField = DocumentMetadataField(
      key: 'signedAt',
      label: 'Fecha',
      type: DocumentMetadataFieldType.date,
      required: false,
    );
    expect(
      dateField.validateValue('2026/03/31'),
      'El campo Fecha debe usar formato AAAA-MM-DD.',
    );
    expect(dateField.validateValue('2026-03-31'), isNull);

    const integerField = DocumentMetadataField(
      key: 'folios',
      label: 'Folios',
      type: DocumentMetadataFieldType.integer,
      required: false,
    );
    expect(
      integerField.validateValue('1.5'),
      'El campo Folios debe ser un entero.',
    );
    expect(integerField.validateValue('15'), isNull);

    const numberField = DocumentMetadataField(
      key: 'amount',
      label: 'Monto',
      type: DocumentMetadataFieldType.number,
      required: false,
    );
    expect(
      numberField.validateValue('abc'),
      'El campo Monto debe ser numérico.',
    );
    expect(numberField.validateValue('15.5'), isNull);

    const booleanField = DocumentMetadataField(
      key: 'approved',
      label: 'Aprobado',
      type: DocumentMetadataFieldType.boolean,
      required: false,
    );
    expect(
      booleanField.validateValue('si'),
      'El campo Aprobado debe ser verdadero o falso.',
    );
    expect(booleanField.validateValue('true'), isNull);
    expect(booleanField.validateValue('false'), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/document_metadata_field.dart';
import 'package:gdms_app/src/documents/domain/document_type_catalog_entry.dart';

void main() {
  test('fromJson parsea metadataSchema y conserva solo entradas mapa', () {
    final entry = DocumentTypeCatalogEntry.fromJson({
      'id': 'type-1',
      'tenantId': 'tenant-1',
      'code': 'LEASE',
      'name': 'Contrato',
      'sector': 'legal',
      'isActive': true,
      'metadataSchema': {
        'signedAt': {
          'label': 'Fecha de firma',
          'type': 'date',
          'required': true,
        },
        'approved': {
          'label': 'Aprobado',
          'type': 'boolean',
          'required': false,
        },
        'ignored': 'not-a-map',
      },
    });

    expect(entry.id, 'type-1');
    expect(entry.tenantId, 'tenant-1');
    expect(entry.code, 'LEASE');
    expect(entry.name, 'Contrato');
    expect(entry.sector, 'legal');
    expect(entry.isActive, isTrue);
    expect(entry.metadataFields, hasLength(2));
    expect(entry.metadataFields.first.key, 'signedAt');
    expect(entry.metadataFields.first.type, DocumentMetadataFieldType.date);
    expect(entry.metadataFields.last.key, 'approved');
    expect(entry.metadataFields.last.type, DocumentMetadataFieldType.boolean);
  });

  test('fromJson usa defaults seguros cuando faltan datos o schema es invalido', () {
    final entry = DocumentTypeCatalogEntry.fromJson({
      'metadataSchema': 'bad',
    });

    expect(entry.id, '');
    expect(entry.tenantId, isNull);
    expect(entry.code, '');
    expect(entry.name, '');
    expect(entry.sector, '');
    expect(entry.isActive, isFalse);
    expect(entry.metadataFields, isEmpty);
  });

  test('displayLabel combina nombre y codigo', () {
    const entry = DocumentTypeCatalogEntry(
      id: 'type-1',
      tenantId: 'tenant-1',
      code: 'LEASE',
      name: 'Contrato',
      sector: 'legal',
      isActive: true,
      metadataFields: [],
    );

    expect(entry.displayLabel, 'Contrato (LEASE)');
  });
}

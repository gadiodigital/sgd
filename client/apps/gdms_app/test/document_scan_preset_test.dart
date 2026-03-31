import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preset.dart';

void main() {
  test('values mantiene el orden operativo esperado', () {
    expect(
      DocumentScanPreset.values.map((preset) => preset.id).toList(),
      ['library-color', 'contracts-gray', 'quick-bw'],
    );
  });

  test('libraryColor define el preset duplex color de archivo', () {
    const preset = DocumentScanPreset.libraryColor;

    expect(preset.label, 'Archivo color');
    expect(preset.description, contains('Duplex color 300 dpi'));
    expect(preset.duplex, isTrue);
    expect(preset.dpi, 300);
    expect(preset.pixelType, 'color');
    expect(preset.discardBlankPages, 'auto');
  });

  test('contractsGray y quickBw representan los perfiles restantes', () {
    const contracts = DocumentScanPreset.contractsGray;
    const quick = DocumentScanPreset.quickBw;

    expect(contracts.label, 'Contratos');
    expect(contracts.duplex, isTrue);
    expect(contracts.pixelType, 'gray');
    expect(contracts.discardBlankPages, 'off');

    expect(quick.label, 'B/N rapido');
    expect(quick.duplex, isFalse);
    expect(quick.dpi, 200);
    expect(quick.pixelType, 'bw');
    expect(quick.discardBlankPages, 'auto');
  });
}

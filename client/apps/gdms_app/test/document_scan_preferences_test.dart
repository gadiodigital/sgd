import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';

void main() {
  tearDown(() {
    DocumentScanPreferences.save(DocumentScanPreferences.defaults);
  });

  test('defaults representa la configuracion base esperada', () {
    final defaults = DocumentScanPreferences.defaults;

    expect(defaults.scannerName, isNull);
    expect(defaults.lastSessionId, isNull);
    expect(defaults.source, ScanSource.adf);
    expect(defaults.duplex, isTrue);
    expect(defaults.dpi, 300);
    expect(defaults.pixelType, 'color');
    expect(defaults.discardBlankPages, 'auto');
  });

  test('save y current mantienen la ultima preferencia persistida', () {
    const preferences = DocumentScanPreferences(
      scannerName: 'Canon DR',
      lastSessionId: 's-3',
      source: ScanSource.flatbed,
      duplex: false,
      dpi: 200,
      pixelType: 'gray',
      discardBlankPages: 'off',
    );

    DocumentScanPreferences.save(preferences);

    expect(DocumentScanPreferences.current.scannerName, 'Canon DR');
    expect(DocumentScanPreferences.current.lastSessionId, 's-3');
    expect(DocumentScanPreferences.current.source, ScanSource.flatbed);
    expect(DocumentScanPreferences.current.duplex, isFalse);
    expect(DocumentScanPreferences.current.dpi, 200);
    expect(DocumentScanPreferences.current.pixelType, 'gray');
    expect(DocumentScanPreferences.current.discardBlankPages, 'off');
  });

  test('copyWith permite actualizar y limpiar scanner y sesion', () {
    const preferences = DocumentScanPreferences(
      scannerName: 'Fujitsu',
      lastSessionId: 's-8',
      source: ScanSource.adf,
      duplex: true,
      dpi: 300,
      pixelType: 'color',
      discardBlankPages: 'auto',
    );

    final updated = preferences.copyWith(
      source: ScanSource.flatbed,
      duplex: false,
      dpi: 150,
      pixelType: 'bw',
      discardBlankPages: 'off',
      clearScannerName: true,
      clearLastSessionId: true,
    );

    expect(updated.scannerName, isNull);
    expect(updated.lastSessionId, isNull);
    expect(updated.source, ScanSource.flatbed);
    expect(updated.duplex, isFalse);
    expect(updated.dpi, 150);
    expect(updated.pixelType, 'bw');
    expect(updated.discardBlankPages, 'off');
  });
}

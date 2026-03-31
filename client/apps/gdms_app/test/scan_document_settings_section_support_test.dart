import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preset.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_settings_section_support.dart';

void main() {
  test('selectedPreset devuelve null sin preset activo o si no existe', () {
    expect(
      ScanDocumentSettingsSectionSupport.selectedPreset(
        DocumentScanPreset.values,
        null,
      ),
      isNull,
    );
    expect(
      ScanDocumentSettingsSectionSupport.selectedPreset(
        DocumentScanPreset.values,
        'missing',
      ),
      isNull,
    );
  });

  test('selectedPreset devuelve el preset correcto por id', () {
    final selected = ScanDocumentSettingsSectionSupport.selectedPreset(
      DocumentScanPreset.values,
      'contracts-gray',
    );

    expect(selected, isNotNull);
    expect(selected!.id, 'contracts-gray');
    expect(selected.label, 'Contratos');
  });

  test('readinessReason prioriza servicio, scanner y capacidades ADF', () {
    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: false,
        hasScanners: true,
        hasSelectedScanner: true,
        duplex: true,
        canScanDuplex: true,
        canScanSimplex: true,
        canScanFlatbed: true,
        canUseAdf: true,
      ),
      'Servicio no disponible',
    );

    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: true,
        hasScanners: false,
        hasSelectedScanner: true,
        duplex: true,
        canScanDuplex: true,
        canScanSimplex: true,
        canScanFlatbed: true,
        canUseAdf: true,
      ),
      'No hay escaneres detectados',
    );

    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: false,
        duplex: true,
        canScanDuplex: true,
        canScanSimplex: true,
        canScanFlatbed: true,
        canUseAdf: true,
      ),
      'Selecciona un escaner',
    );

    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: true,
        duplex: true,
        canScanDuplex: true,
        canScanSimplex: true,
        canScanFlatbed: true,
        canUseAdf: false,
      ),
      'El host no soporta ADF',
    );
  });

  test('readinessReason cubre flatbed, duplex, simplex y fallback final', () {
    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.flatbed,
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: true,
        duplex: false,
        canScanDuplex: true,
        canScanSimplex: true,
        canScanFlatbed: false,
        canUseAdf: true,
      ),
      'El host no soporta cama plana',
    );

    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: true,
        duplex: true,
        canScanDuplex: false,
        canScanSimplex: true,
        canScanFlatbed: true,
        canUseAdf: true,
      ),
      'El host no soporta duplex',
    );

    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: true,
        duplex: false,
        canScanDuplex: true,
        canScanSimplex: false,
        canScanFlatbed: true,
        canUseAdf: true,
      ),
      'El host no soporta simplex',
    );

    expect(
      ScanDocumentSettingsSectionSupport.readinessReason(
        source: ScanSource.adf,
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: true,
        duplex: false,
        canScanDuplex: true,
        canScanSimplex: true,
        canScanFlatbed: true,
        canUseAdf: true,
      ),
      'Configuracion no disponible',
    );
  });
}

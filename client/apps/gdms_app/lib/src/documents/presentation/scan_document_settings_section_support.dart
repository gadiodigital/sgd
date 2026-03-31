import '../application/document_scan_preset.dart';

import '../domain/scan_source.dart';

final class ScanDocumentSettingsSectionSupport {
  static DocumentScanPreset? selectedPreset(
    List<DocumentScanPreset> presets,
    String? activePresetId,
  ) {
    if (activePresetId == null) return null;
    for (final preset in presets) {
      if (preset.id == activePresetId) return preset;
    }
    return null;
  }

  static String readinessReason({
    required ScanSource source,
    required bool serviceAvailable,
    required bool hasScanners,
    required bool hasSelectedScanner,
    required bool duplex,
    required bool canScanDuplex,
    required bool canScanSimplex,
    required bool canScanFlatbed,
    required bool canUseAdf,
  }) {
    if (!serviceAvailable) {
      return 'Servicio no disponible';
    }
    if (!hasScanners) {
      return 'No hay escaneres detectados';
    }
    if (!hasSelectedScanner) {
      return 'Selecciona un escaner';
    }
    if (source == ScanSource.flatbed && !canScanFlatbed) {
      return 'El host no soporta cama plana';
    }
    if (source == ScanSource.adf && !canUseAdf) {
      return 'El host no soporta ADF';
    }
    if (duplex && !canScanDuplex) {
      return 'El host no soporta duplex';
    }
    if (!duplex && !canScanSimplex) {
      return 'El host no soporta simplex';
    }
    return 'Configuracion no disponible';
  }
}

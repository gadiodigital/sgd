import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

void main() {
  test('catalogo expone los 4 presets esperados en el orden operativo definido', () {
    final presets = ScanDocumentActiveSessionsPresetCatalog.values;

    expect(presets, hasLength(4));
    expect(
      presets.map((preset) => preset.id),
      [
        ScanDocumentActiveSessionsPreset.attention,
        ScanDocumentActiveSessionsPreset.oldErrors,
        ScanDocumentActiveSessionsPreset.recentAdf,
        ScanDocumentActiveSessionsPreset.flatbed,
      ],
    );
  });

  test('configs de preset mantienen labels descripciones y filtros esperados', () {
    final attention = ScanDocumentActiveSessionsPresetCatalog.findById(
      ScanDocumentActiveSessionsPreset.attention,
    )!;
    final oldErrors = ScanDocumentActiveSessionsPresetCatalog.findById(
      ScanDocumentActiveSessionsPreset.oldErrors,
    )!;
    final recentAdf = ScanDocumentActiveSessionsPresetCatalog.findById(
      ScanDocumentActiveSessionsPreset.recentAdf,
    )!;
    final flatbed = ScanDocumentActiveSessionsPresetCatalog.findById(
      ScanDocumentActiveSessionsPreset.flatbed,
    )!;

    expect(attention.label, 'Atencion');
    expect(attention.description, 'Errores, rehidratadas o inactivas');
    expect(attention.filter, ScanDocumentSessionFilter.attention);
    expect(attention.statusFilter, ScanDocumentSessionStatusFilter.all);
    expect(
      attention.pageVolumeFilter,
      ScanDocumentSessionPageVolumeFilter.all,
    );
    expect(attention.activityFilter, ScanDocumentSessionActivityFilter.all);

    expect(oldErrors.label, 'Errores viejos');
    expect(
      oldErrors.description,
      'Sesiones con error de hace mas de 1 hora',
    );
    expect(oldErrors.filter, ScanDocumentSessionFilter.all);
    expect(oldErrors.statusFilter, ScanDocumentSessionStatusFilter.error);
    expect(
      oldErrors.pageVolumeFilter,
      ScanDocumentSessionPageVolumeFilter.all,
    );
    expect(
      oldErrors.activityFilter,
      ScanDocumentSessionActivityFilter.olderThanHour,
    );

    expect(recentAdf.label, 'ADF recientes');
    expect(
      recentAdf.description,
      'ADF tocadas en los ultimos 15 minutos',
    );
    expect(recentAdf.filter, ScanDocumentSessionFilter.adf);
    expect(recentAdf.statusFilter, ScanDocumentSessionStatusFilter.all);
    expect(
      recentAdf.pageVolumeFilter,
      ScanDocumentSessionPageVolumeFilter.all,
    );
    expect(
      recentAdf.activityFilter,
      ScanDocumentSessionActivityFilter.last15Minutes,
    );

    expect(flatbed.label, 'Cama plana');
    expect(flatbed.description, 'Solo sesiones de cama plana');
    expect(flatbed.filter, ScanDocumentSessionFilter.flatbed);
    expect(flatbed.statusFilter, ScanDocumentSessionStatusFilter.all);
    expect(flatbed.pageVolumeFilter, ScanDocumentSessionPageVolumeFilter.all);
    expect(flatbed.activityFilter, ScanDocumentSessionActivityFilter.all);
  });

  test('findById devuelve null con null y resuelve cada preset por id', () {
    expect(ScanDocumentActiveSessionsPresetCatalog.findById(null), isNull);

    for (final preset in ScanDocumentActiveSessionsPresetCatalog.values) {
      expect(
        ScanDocumentActiveSessionsPresetCatalog.findById(preset.id),
        same(preset),
      );
    }
  });
}

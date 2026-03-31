import 'scan_document_active_sessions_support.dart';

enum ScanDocumentActiveSessionsPreset {
  attention,
  oldErrors,
  recentAdf,
  flatbed,
}

final class ScanDocumentActiveSessionsPresetConfig {
  const ScanDocumentActiveSessionsPresetConfig({
    required this.id,
    required this.label,
    required this.description,
    required this.filter,
    required this.statusFilter,
    required this.pageVolumeFilter,
    required this.activityFilter,
  });

  final ScanDocumentActiveSessionsPreset id;
  final String label;
  final String description;
  final ScanDocumentSessionFilter filter;
  final ScanDocumentSessionStatusFilter statusFilter;
  final ScanDocumentSessionPageVolumeFilter pageVolumeFilter;
  final ScanDocumentSessionActivityFilter activityFilter;
}

final class ScanDocumentActiveSessionsPresetCatalog {
  static const values = [
    ScanDocumentActiveSessionsPresetConfig(
      id: ScanDocumentActiveSessionsPreset.attention,
      label: 'Atencion',
      description: 'Errores, rehidratadas o inactivas',
      filter: ScanDocumentSessionFilter.attention,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
    ),
    ScanDocumentActiveSessionsPresetConfig(
      id: ScanDocumentActiveSessionsPreset.oldErrors,
      label: 'Errores viejos',
      description: 'Sesiones con error de hace mas de 1 hora',
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.error,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.olderThanHour,
    ),
    ScanDocumentActiveSessionsPresetConfig(
      id: ScanDocumentActiveSessionsPreset.recentAdf,
      label: 'ADF recientes',
      description: 'ADF tocadas en los ultimos 15 minutos',
      filter: ScanDocumentSessionFilter.adf,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.last15Minutes,
    ),
    ScanDocumentActiveSessionsPresetConfig(
      id: ScanDocumentActiveSessionsPreset.flatbed,
      label: 'Cama plana',
      description: 'Solo sesiones de cama plana',
      filter: ScanDocumentSessionFilter.flatbed,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
    ),
  ];

  static ScanDocumentActiveSessionsPresetConfig? findById(
    ScanDocumentActiveSessionsPreset? id,
  ) {
    if (id == null) {
      return null;
    }
    for (final preset in values) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}

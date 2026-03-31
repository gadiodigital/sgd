import 'scan_document_active_sessions_support.dart';

final class ScanDocumentActiveSessionsLabels {
  static String filterLabel(ScanDocumentSessionFilter filter) {
    return switch (filter) {
      ScanDocumentSessionFilter.all => 'Todas',
      ScanDocumentSessionFilter.attention => 'Requieren atencion',
      ScanDocumentSessionFilter.rehydrated => 'Rehidratadas',
      ScanDocumentSessionFilter.stale => 'Inactivas',
      ScanDocumentSessionFilter.adf => 'ADF',
      ScanDocumentSessionFilter.flatbed => 'Cama plana',
    };
  }

  static String sortLabel(ScanDocumentSessionSort sort) {
    return switch (sort) {
      ScanDocumentSessionSort.attentionFirst => 'Atencion primero',
      ScanDocumentSessionSort.recentActivity => 'Actividad reciente',
      ScanDocumentSessionSort.oldestActivity => 'Actividad mas antigua',
      ScanDocumentSessionSort.newest => 'Sesion mas nueva',
      ScanDocumentSessionSort.largest => 'Mas paginas',
    };
  }

  static String statusFilterLabel(
    ScanDocumentSessionStatusFilter statusFilter,
  ) {
    return switch (statusFilter) {
      ScanDocumentSessionStatusFilter.all => 'Todos',
      ScanDocumentSessionStatusFilter.running => 'Running',
      ScanDocumentSessionStatusFilter.completed => 'Completed',
      ScanDocumentSessionStatusFilter.error => 'Error',
    };
  }

  static String pageVolumeFilterLabel(
    ScanDocumentSessionPageVolumeFilter filter,
  ) {
    return switch (filter) {
      ScanDocumentSessionPageVolumeFilter.all => 'Todas las paginas',
      ScanDocumentSessionPageVolumeFilter.singlePage => '1 pagina',
      ScanDocumentSessionPageVolumeFilter.smallBatch => '2 a 5 paginas',
      ScanDocumentSessionPageVolumeFilter.largeBatch => '6+ paginas',
    };
  }

  static String activityFilterLabel(ScanDocumentSessionActivityFilter filter) {
    return switch (filter) {
      ScanDocumentSessionActivityFilter.all => 'Toda actividad',
      ScanDocumentSessionActivityFilter.last15Minutes => 'Ultimos 15 min',
      ScanDocumentSessionActivityFilter.lastHour => 'Ultima hora',
      ScanDocumentSessionActivityFilter.olderThanHour => 'Mas de 1 hora',
    };
  }

  static String scannerFilterLabel(String scanner) => 'Scanner: $scanner';

  static String queryFilterLabel(String query) => 'Texto: $query';
}

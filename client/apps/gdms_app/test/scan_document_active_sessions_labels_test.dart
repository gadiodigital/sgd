import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_labels.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

void main() {
  test('filterLabel cubre todos los filtros operativos', () {
    expect(
      ScanDocumentActiveSessionsLabels.filterLabel(
        ScanDocumentSessionFilter.all,
      ),
      'Todas',
    );
    expect(
      ScanDocumentActiveSessionsLabels.filterLabel(
        ScanDocumentSessionFilter.attention,
      ),
      'Requieren atencion',
    );
    expect(
      ScanDocumentActiveSessionsLabels.filterLabel(
        ScanDocumentSessionFilter.rehydrated,
      ),
      'Rehidratadas',
    );
    expect(
      ScanDocumentActiveSessionsLabels.filterLabel(
        ScanDocumentSessionFilter.stale,
      ),
      'Inactivas',
    );
    expect(
      ScanDocumentActiveSessionsLabels.filterLabel(ScanDocumentSessionFilter.adf),
      'ADF',
    );
    expect(
      ScanDocumentActiveSessionsLabels.filterLabel(
        ScanDocumentSessionFilter.flatbed,
      ),
      'Cama plana',
    );
  });

  test('sortLabel cubre todos los ordenes visibles', () {
    expect(
      ScanDocumentActiveSessionsLabels.sortLabel(
        ScanDocumentSessionSort.attentionFirst,
      ),
      'Atencion primero',
    );
    expect(
      ScanDocumentActiveSessionsLabels.sortLabel(
        ScanDocumentSessionSort.recentActivity,
      ),
      'Actividad reciente',
    );
    expect(
      ScanDocumentActiveSessionsLabels.sortLabel(
        ScanDocumentSessionSort.oldestActivity,
      ),
      'Actividad mas antigua',
    );
    expect(
      ScanDocumentActiveSessionsLabels.sortLabel(ScanDocumentSessionSort.newest),
      'Sesion mas nueva',
    );
    expect(
      ScanDocumentActiveSessionsLabels.sortLabel(ScanDocumentSessionSort.largest),
      'Mas paginas',
    );
  });

  test('status pageVolume y activity labels cubren todos los enums', () {
    expect(
      ScanDocumentActiveSessionsLabels.statusFilterLabel(
        ScanDocumentSessionStatusFilter.all,
      ),
      'Todos',
    );
    expect(
      ScanDocumentActiveSessionsLabels.statusFilterLabel(
        ScanDocumentSessionStatusFilter.running,
      ),
      'Running',
    );
    expect(
      ScanDocumentActiveSessionsLabels.statusFilterLabel(
        ScanDocumentSessionStatusFilter.completed,
      ),
      'Completed',
    );
    expect(
      ScanDocumentActiveSessionsLabels.statusFilterLabel(
        ScanDocumentSessionStatusFilter.error,
      ),
      'Error',
    );

    expect(
      ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(
        ScanDocumentSessionPageVolumeFilter.all,
      ),
      'Todas las paginas',
    );
    expect(
      ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(
        ScanDocumentSessionPageVolumeFilter.singlePage,
      ),
      '1 pagina',
    );
    expect(
      ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(
        ScanDocumentSessionPageVolumeFilter.smallBatch,
      ),
      '2 a 5 paginas',
    );
    expect(
      ScanDocumentActiveSessionsLabels.pageVolumeFilterLabel(
        ScanDocumentSessionPageVolumeFilter.largeBatch,
      ),
      '6+ paginas',
    );

    expect(
      ScanDocumentActiveSessionsLabels.activityFilterLabel(
        ScanDocumentSessionActivityFilter.all,
      ),
      'Toda actividad',
    );
    expect(
      ScanDocumentActiveSessionsLabels.activityFilterLabel(
        ScanDocumentSessionActivityFilter.last15Minutes,
      ),
      'Ultimos 15 min',
    );
    expect(
      ScanDocumentActiveSessionsLabels.activityFilterLabel(
        ScanDocumentSessionActivityFilter.lastHour,
      ),
      'Ultima hora',
    );
    expect(
      ScanDocumentActiveSessionsLabels.activityFilterLabel(
        ScanDocumentSessionActivityFilter.olderThanHour,
      ),
      'Mas de 1 hora',
    );
  });

  test('scannerFilterLabel y queryFilterLabel preservan el valor visible', () {
    expect(
      ScanDocumentActiveSessionsLabels.scannerFilterLabel('Canon fi-7160'),
      'Scanner: Canon fi-7160',
    );
    expect(
      ScanDocumentActiveSessionsLabels.queryFilterLabel('s-3 error'),
      'Texto: s-3 error',
    );
  });
}

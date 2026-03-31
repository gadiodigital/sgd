import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_view_data.dart';

import 'scan_document_active_sessions_test_support.dart';

void main() {
  test('resolver calcula recomendacion preset activo y etiquetas derivadas', () {
    final viewData = ScanDocumentActiveSessionsViewDataResolver.resolve(
      sessions: buildActiveSessionsFixture(),
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.error,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.largeBatch,
      activityFilter: ScanDocumentSessionActivityFilter.olderThanHour,
      sort: ScanDocumentSessionSort.attentionFirst,
      selectedPreset: ScanDocumentActiveSessionsPreset.oldErrors,
      selectedScanner: 'Canon',
      query: '  s-3  ',
      showAllSessions: false,
    );

    expect(viewData.filteredSessions.map((item) => item.sessionId), ['s-3']);
    expect(viewData.visibleSessions.map((item) => item.sessionId), ['s-3']);
    expect(viewData.summary.totalSessions, 1);
    expect(viewData.recommendedPreset?.availability.preset.id, ScanDocumentActiveSessionsPreset.oldErrors);
    expect(
      viewData.recommendedPreset?.reason,
      'Hay errores viejos acumulados y conviene resolverlos primero.',
    );
    expect(viewData.activePreset?.id, ScanDocumentActiveSessionsPreset.oldErrors);
    expect(viewData.activePreset?.label, 'Errores viejos');
    expect(
      viewData.activeFilterLabels,
      containsAll([
        'Error',
        '6+ paginas',
        'Mas de 1 hora',
        'Atencion primero',
        'Scanner: Canon',
        'Texto: s-3',
      ]),
    );
    expect(viewData.scannerOptions, ['Canon', 'Epson']);
    expect(viewData.prioritySessionId, 's-3');
    expect(viewData.prioritySession?.sessionId, 's-3');
    expect(viewData.firstAttentionSessionId, 's-3');
    expect(viewData.errorSessions.map((item) => item.sessionId), ['s-3']);
    expect(viewData.runningSessions, isEmpty);
  });

  test('resolver limita visibles a 6 y mantiene prioridad dentro del subset', () {
    final sessions = [
      buildActiveScanSession(
        sessionId: 's-1',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 1),
      ),
      buildActiveScanSession(
        sessionId: 's-2',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 2),
      ),
      buildActiveScanSession(
        sessionId: 's-3',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 3),
      ),
      buildActiveScanSession(
        sessionId: 's-4',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 4),
      ),
      buildActiveScanSession(
        sessionId: 's-5',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 2,
        touchedAgo: const Duration(minutes: 5),
      ),
      buildActiveScanSession(
        sessionId: 's-6',
        scannerName: 'Canon',
        mode: 'adf-simplex',
        status: 'completed',
        pageCount: 2,
        touchedAgo: const Duration(hours: 2),
      ),
      buildActiveScanSession(
        sessionId: 's-7',
        scannerName: 'Canon',
        mode: 'adf-duplex',
        status: 'error',
        pageCount: 8,
        touchedAgo: const Duration(hours: 3),
      ),
    ];

    final collapsed = ScanDocumentActiveSessionsViewDataResolver.resolve(
      sessions: sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      selectedPreset: null,
      selectedScanner: '',
      query: '',
      showAllSessions: false,
    );
    final expanded = ScanDocumentActiveSessionsViewDataResolver.resolve(
      sessions: sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      selectedPreset: null,
      selectedScanner: '',
      query: '',
      showAllSessions: true,
    );

    expect(collapsed.filteredSessions.length, 7);
    expect(collapsed.visibleSessions.length, 6);
    expect(collapsed.visibleSessions.map((item) => item.sessionId), [
      's-1',
      's-2',
      's-3',
      's-4',
      's-5',
      's-6',
    ]);
    expect(collapsed.prioritySessionId, 's-6');
    expect(collapsed.prioritySession?.sessionId, 's-6');
    expect(expanded.visibleSessions.length, 7);
    expect(expanded.prioritySessionId, 's-6');
    expect(expanded.prioritySession?.sessionId, 's-6');
    expect(expanded.firstAttentionSessionId, 's-6');
    expect(expanded.errorSessions.map((item) => item.sessionId), ['s-7']);
    expect(expanded.runningSessions.length, 5);
  });

  test('resolver omite labels inactivos cuando la vista esta en estado base', () {
    final viewData = ScanDocumentActiveSessionsViewDataResolver.resolve(
      sessions: buildActiveSessionsFixture(),
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      selectedPreset: null,
      selectedScanner: '',
      query: '   ',
      showAllSessions: true,
    );

    expect(viewData.activePreset, isNull);
    expect(viewData.activeFilterLabels, isEmpty);
    expect(viewData.visibleSessions.length, 3);
    expect(viewData.scannerOptions, ['Canon', 'Epson']);
  });
}

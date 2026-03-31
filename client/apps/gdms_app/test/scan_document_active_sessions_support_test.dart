import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

void main() {
  final sessions = [
    ActiveScanSession(
      sessionId: 'session-adf',
      createdAtUtc: DateTime.utc(2026, 3, 28, 12, 0),
      lastTouchedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(minutes: 5),
      ),
      scannerName: 'EPSON DS-570W',
      mode: 'adf-duplex',
      status: 'completed',
      pageCount: 3,
      isRehydrated: true,
    ),
    ActiveScanSession(
      sessionId: 'session-flatbed',
      createdAtUtc: DateTime.utc(2026, 3, 28, 11, 0),
      lastTouchedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(hours: 3),
      ),
      scannerName: 'Brother Flatbed',
      mode: 'flatbed-single',
      status: 'error',
      pageCount: 1,
      isRehydrated: false,
    ),
    ActiveScanSession(
      sessionId: 'session-running',
      createdAtUtc: DateTime.utc(2026, 3, 28, 10, 0),
      lastTouchedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(minutes: 1),
      ),
      scannerName: 'Canon ADF',
      mode: 'adf-simplex',
      status: 'running',
      pageCount: 2,
      isRehydrated: false,
    ),
  ];

  test('filtra sesiones rehidratadas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.rehydrated,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-adf');
  });

  test('filtra sesiones inactivas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.stale,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-flatbed');
  });

  test('filtra sesiones que requieren atencion', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.attention,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(2));
    expect(filtered.map((session) => session.sessionId), contains('session-adf'));
    expect(
      filtered.map((session) => session.sessionId),
      contains('session-flatbed'),
    );
  });

  test('busca por scanner o sesion', () {
    final byScanner = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: 'brother',
    );
    final bySession = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: 'session-adf',
    );

    expect(byScanner.single.sessionId, 'session-flatbed');
    expect(bySession.single.sessionId, 'session-adf');
  });

  test('ordena por cantidad de paginas', () {
    final ordered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.largest,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(ordered.first.sessionId, 'session-adf');
    expect(ordered.last.sessionId, 'session-flatbed');
  });

  test('ordena poniendo atencion primero', () {
    final ordered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.attentionFirst,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(ordered.first.sessionId, 'session-adf');
    expect(ordered[1].sessionId, 'session-flatbed');
    expect(ordered.last.sessionId, 'session-running');
  });

  test('resume metricas del subconjunto', () {
    final summary = ScanDocumentActiveSessionsSupport.summarizeSessions(
      sessions,
    );

    expect(summary.totalSessions, 3);
    expect(summary.totalPages, 6);
    expect(summary.attentionSessions, 2);
    expect(summary.rehydratedSessions, 1);
    expect(summary.staleSessions, 1);
    expect(summary.completedSessions, 1);
    expect(summary.errorSessions, 1);
    expect(summary.runningSessions, 1);
    expect(summary.uniqueScanners, 3);
    expect(summary.primaryScannerLabel, 'EPSON DS-570W');
    expect(summary.adfSessions, 2);
    expect(summary.flatbedSessions, 1);
    expect(summary.mostRecentActivityAtUtc, isNotNull);
    expect(summary.oldestActivityAtUtc, isNotNull);
    expect(
      summary.mostRecentActivityAtUtc!.isAfter(summary.oldestActivityAtUtc!) ||
          summary.mostRecentActivityAtUtc ==
              summary.oldestActivityAtUtc,
      isTrue,
    );
  });

  test('filtra sesiones por estado', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.error,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-flatbed');
  });

  test('filtra sesiones por scanner exacto', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: 'Canon ADF',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-running');
  });

  test('filtra sesiones por volumen de paginas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.singlePage,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-flatbed');
  });

  test('filtra sesiones por antiguedad de actividad', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.olderThanHour,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-flatbed');
  });

  test('normaliza etiquetas de estado', () {
    expect(ScanDocumentActiveSessionsSupport.statusLabel('completed'), 'Completed');
    expect(ScanDocumentActiveSessionsSupport.statusLabel('error'), 'Error');
    expect(ScanDocumentActiveSessionsSupport.statusLabel(' running '), 'Running');
    expect(ScanDocumentActiveSessionsSupport.statusLabel('empty'), 'Empty');
    expect(ScanDocumentActiveSessionsSupport.statusLabel('canceled'), 'Canceled');
    expect(ScanDocumentActiveSessionsSupport.statusLabel('custom'), 'custom');
    expect(ScanDocumentActiveSessionsSupport.statusLabel(''), 'Sin estado');
  });

  test('formatea fecha y hora local con padding', () {
    final formatted = ScanDocumentActiveSessionsSupport.formatDateTime(
      DateTime.utc(2026, 3, 5, 8, 7),
    );

    expect(formatted, '05/03/2026 05:07');
  });
}

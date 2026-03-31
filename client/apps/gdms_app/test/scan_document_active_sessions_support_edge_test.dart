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

  test('normaliza query con espacios y mayusculas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '  BROTHER  ',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-flatbed');
  });

  test('normaliza scanner seleccionado con espacios y mayusculas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '  canon adf  ',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-running');
  });

  test('considera empty y canceled como sesiones con atencion', () {
    final extraSessions = [
      ...sessions,
      ActiveScanSession(
        sessionId: 'session-empty',
        createdAtUtc: DateTime.utc(2026, 3, 28, 9, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(minutes: 30),
        ),
        scannerName: 'Canon ADF',
        mode: 'adf-simplex',
        status: 'empty',
        pageCount: 0,
        isRehydrated: false,
      ),
      ActiveScanSession(
        sessionId: 'session-canceled',
        createdAtUtc: DateTime.utc(2026, 3, 28, 8, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(minutes: 40),
        ),
        scannerName: 'Canon ADF',
        mode: 'adf-simplex',
        status: 'canceled',
        pageCount: 0,
        isRehydrated: false,
      ),
    ];

    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      extraSessions,
      filter: ScanDocumentSessionFilter.attention,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(
      filtered.map((session) => session.sessionId),
      containsAll(['session-empty', 'session-canceled']),
    );
  });

  test('resume lote vacio con scanner principal sin dato', () {
    final summary = ScanDocumentActiveSessionsSupport.summarizeSessions(
      const [],
    );

    expect(summary.totalSessions, 0);
    expect(summary.totalPages, 0);
    expect(summary.attentionSessions, 0);
    expect(summary.primaryScannerLabel, 'sin dato');
    expect(summary.uniqueScanners, 0);
    expect(summary.mostRecentActivityAtUtc, isNull);
    expect(summary.oldestActivityAtUtc, isNull);
  });

  test('normaliza scanner vacio como Sin scanner en el resumen', () {
    final summary = ScanDocumentActiveSessionsSupport.summarizeSessions([
      ActiveScanSession(
        sessionId: 'session-no-scanner',
        createdAtUtc: DateTime.utc(2026, 3, 28, 7, 0),
        lastTouchedAtUtc: DateTime.utc(2026, 3, 28, 7, 15),
        scannerName: '   ',
        mode: 'flatbed-single',
        status: 'completed',
        pageCount: 4,
        isRehydrated: false,
      ),
    ]);

    expect(summary.totalSessions, 1);
    expect(summary.uniqueScanners, 1);
    expect(summary.primaryScannerLabel, 'Sin scanner');
    expect(summary.flatbedSessions, 1);
  });

  test('mantiene el primer scanner dominante cuando hay empate de volumen', () {
    final summary = ScanDocumentActiveSessionsSupport.summarizeSessions([
      ActiveScanSession(
        sessionId: 'session-a1',
        createdAtUtc: DateTime.utc(2026, 3, 28, 7, 0),
        lastTouchedAtUtc: DateTime.utc(2026, 3, 28, 7, 10),
        scannerName: 'Scanner A',
        mode: 'adf-simplex',
        status: 'completed',
        pageCount: 1,
        isRehydrated: false,
      ),
      ActiveScanSession(
        sessionId: 'session-b1',
        createdAtUtc: DateTime.utc(2026, 3, 28, 8, 0),
        lastTouchedAtUtc: DateTime.utc(2026, 3, 28, 8, 10),
        scannerName: 'Scanner B',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 1,
        isRehydrated: false,
      ),
    ]);

    expect(summary.uniqueScanners, 2);
    expect(summary.primaryScannerLabel, 'Scanner A');
  });

  test('excluye exactamente 15 minutos del filtro ultimos 15 minutos', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions([
      ActiveScanSession(
        sessionId: 'session-15m',
        createdAtUtc: DateTime.utc(2026, 3, 28, 9, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(minutes: 15),
        ),
        scannerName: 'Scanner A',
        mode: 'adf-simplex',
        status: 'completed',
        pageCount: 1,
        isRehydrated: false,
      ),
    ],
        filter: ScanDocumentSessionFilter.all,
        statusFilter: ScanDocumentSessionStatusFilter.all,
        sort: ScanDocumentSessionSort.recentActivity,
        pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
        activityFilter: ScanDocumentSessionActivityFilter.last15Minutes,
        selectedScanner: '',
        query: '');

    expect(filtered, isEmpty);
  });

  test('incluye exactamente 1 hora en olderThanHour y la excluye de lastHour', () {
    final sessionsAtBoundary = [
      ActiveScanSession(
        sessionId: 'session-1h',
        createdAtUtc: DateTime.utc(2026, 3, 28, 9, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(hours: 1),
        ),
        scannerName: 'Scanner B',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 1,
        isRehydrated: false,
      ),
    ];

    final lastHour = ScanDocumentActiveSessionsSupport.filterSessions(
      sessionsAtBoundary,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.lastHour,
      selectedScanner: '',
      query: '',
    );
    final olderThanHour = ScanDocumentActiveSessionsSupport.filterSessions(
      sessionsAtBoundary,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.olderThanHour,
      selectedScanner: '',
      query: '',
    );

    expect(lastHour, isEmpty);
    expect(olderThanHour, hasLength(1));
    expect(olderThanHour.single.sessionId, 'session-1h');
  });

}

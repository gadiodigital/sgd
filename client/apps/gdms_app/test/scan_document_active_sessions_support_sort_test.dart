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

  test('ordena recentActivity por ultima actividad descendente', () {
    final ordered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(
      ordered.map((session) => session.sessionId).toList(),
      ['session-running', 'session-adf', 'session-flatbed'],
    );
  });

  test('ordena oldestActivity por ultima actividad ascendente', () {
    final ordered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.oldestActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(
      ordered.map((session) => session.sessionId).toList(),
      ['session-flatbed', 'session-adf', 'session-running'],
    );
  });

  test('ordena newest por fecha de creacion descendente', () {
    final ordered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.newest,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(
      ordered.map((session) => session.sessionId).toList(),
      ['session-adf', 'session-flatbed', 'session-running'],
    );
  });

  test('desempata attentionFirst por actividad mas reciente entre afectados', () {
    final attentionSessions = [
      ActiveScanSession(
        sessionId: 'session-stale-recent',
        createdAtUtc: DateTime.utc(2026, 3, 28, 9, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(hours: 2, minutes: 5),
        ),
        scannerName: 'Scanner A',
        mode: 'adf-simplex',
        status: 'completed',
        pageCount: 1,
        isRehydrated: false,
      ),
      ActiveScanSession(
        sessionId: 'session-stale-old',
        createdAtUtc: DateTime.utc(2026, 3, 28, 8, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(hours: 4),
        ),
        scannerName: 'Scanner B',
        mode: 'flatbed-single',
        status: 'error',
        pageCount: 1,
        isRehydrated: false,
      ),
      ActiveScanSession(
        sessionId: 'session-normal',
        createdAtUtc: DateTime.utc(2026, 3, 28, 10, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(minutes: 10),
        ),
        scannerName: 'Scanner C',
        mode: 'adf-simplex',
        status: 'running',
        pageCount: 1,
        isRehydrated: false,
      ),
    ];

    final ordered = ScanDocumentActiveSessionsSupport.filterSessions(
      attentionSessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.attentionFirst,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.all,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(
      ordered.map((session) => session.sessionId).toList(),
      ['session-stale-recent', 'session-stale-old', 'session-normal'],
    );
  });
}

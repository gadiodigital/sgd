import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_support.dart';

void main() {
  final sessions = [
    ActiveScanSession(
      sessionId: 'session-single',
      createdAtUtc: DateTime.utc(2026, 3, 28, 12, 0),
      lastTouchedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(minutes: 5),
      ),
      scannerName: 'Scanner A',
      mode: 'flatbed-single',
      status: 'completed',
      pageCount: 1,
      isRehydrated: false,
    ),
    ActiveScanSession(
      sessionId: 'session-small',
      createdAtUtc: DateTime.utc(2026, 3, 28, 11, 0),
      lastTouchedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(minutes: 10),
      ),
      scannerName: 'Scanner B',
      mode: 'adf-simplex',
      status: 'running',
      pageCount: 4,
      isRehydrated: false,
    ),
    ActiveScanSession(
      sessionId: 'session-large',
      createdAtUtc: DateTime.utc(2026, 3, 28, 10, 0),
      lastTouchedAtUtc: DateTime.now().toUtc().subtract(
        const Duration(minutes: 15),
      ),
      scannerName: 'Scanner C',
      mode: 'adf-duplex',
      status: 'completed',
      pageCount: 6,
      isRehydrated: false,
    ),
  ];

  test('filtra smallBatch entre 2 y 5 paginas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.smallBatch,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-small');
  });

  test('filtra largeBatch con 6 paginas o mas', () {
    final filtered = ScanDocumentActiveSessionsSupport.filterSessions(
      sessions,
      filter: ScanDocumentSessionFilter.all,
      statusFilter: ScanDocumentSessionStatusFilter.all,
      sort: ScanDocumentSessionSort.recentActivity,
      pageVolumeFilter: ScanDocumentSessionPageVolumeFilter.largeBatch,
      activityFilter: ScanDocumentSessionActivityFilter.all,
      selectedScanner: '',
      query: '',
    );

    expect(filtered, hasLength(1));
    expect(filtered.single.sessionId, 'session-large');
  });
}

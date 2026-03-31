import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_active_sessions_preset_support.dart';

void main() {
  test('resuelve conteos por preset sobre el lote activo', () {
    final sessions = [
      ActiveScanSession(
        sessionId: 'recent-adf',
        createdAtUtc: DateTime.utc(2026, 3, 28, 12, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(minutes: 5),
        ),
        scannerName: 'Scanner A',
        mode: 'adf-duplex',
        status: 'running',
        pageCount: 3,
        isRehydrated: false,
      ),
      ActiveScanSession(
        sessionId: 'old-error',
        createdAtUtc: DateTime.utc(2026, 3, 28, 11, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(hours: 2),
        ),
        scannerName: 'Scanner B',
        mode: 'adf-simplex',
        status: 'error',
        pageCount: 1,
        isRehydrated: false,
      ),
      ActiveScanSession(
        sessionId: 'flatbed',
        createdAtUtc: DateTime.utc(2026, 3, 28, 10, 0),
        lastTouchedAtUtc: DateTime.now().toUtc().subtract(
          const Duration(minutes: 20),
        ),
        scannerName: 'Scanner C',
        mode: 'flatbed-single',
        status: 'completed',
        pageCount: 2,
        isRehydrated: false,
      ),
    ];

    final availabilities =
        ScanDocumentActiveSessionsPresetSupport.resolveAvailabilities(sessions);

    final byId = {
      for (final item in availabilities) item.preset.id: item.matchCount,
    };
    expect(byId[ScanDocumentActiveSessionsPreset.attention], 1);
    expect(byId[ScanDocumentActiveSessionsPreset.oldErrors], 1);
    expect(byId[ScanDocumentActiveSessionsPreset.recentAdf], 1);
    expect(byId[ScanDocumentActiveSessionsPreset.flatbed], 1);
  });

  test('marca preset sin matches como no disponible', () {
    final availabilities =
        ScanDocumentActiveSessionsPresetSupport.resolveAvailabilities(const []);

    expect(availabilities, hasLength(4));
    expect(availabilities.every((item) => item.matchCount == 0), isTrue);
    expect(availabilities.every((item) => item.hasMatches == false), isTrue);
  });

  test('recomienda errores viejos por encima del resto', () {
    final recommendation =
        ScanDocumentActiveSessionsPresetSupport.recommendPreset([
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values[0],
            matchCount: 2,
          ),
          ScanDocumentActiveSessionsPresetAvailability(
            preset: ScanDocumentActiveSessionsPresetCatalog.values[1],
            matchCount: 1,
          ),
        ]);

    expect(
      recommendation?.availability.preset.id,
      ScanDocumentActiveSessionsPreset.oldErrors,
    );
    expect(
      recommendation?.reason,
      'Hay errores viejos acumulados y conviene resolverlos primero.',
    );
  });

  test('no recomienda nada si no hay presets con coincidencias', () {
    final recommendation =
        ScanDocumentActiveSessionsPresetSupport.recommendPreset([
          for (final preset in ScanDocumentActiveSessionsPresetCatalog.values)
            ScanDocumentActiveSessionsPresetAvailability(
              preset: preset,
              matchCount: 0,
            ),
        ]);

    expect(recommendation, isNull);
  });
}

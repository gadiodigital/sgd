import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/active_scan_session.dart';

void main() {
  test('fromJson normaliza strings y parsea fechas validas', () {
    final session = ActiveScanSession.fromJson({
      'sessionId': '  s-1  ',
      'createdAtUtc': '2026-03-31T10:15:00-03:00',
      'lastTouchedAtUtc': '2026-03-31T11:00:00-03:00',
      'scannerName': '  Fujitsu  ',
      'mode': '  adf-duplex  ',
      'status': '  running  ',
      'pageCount': 7,
      'isRehydrated': true,
    });

    expect(session.sessionId, 's-1');
    expect(session.scannerName, 'Fujitsu');
    expect(session.mode, 'adf-duplex');
    expect(session.status, 'running');
    expect(session.pageCount, 7);
    expect(session.isRehydrated, isTrue);
    expect(session.createdAtUtc, DateTime.parse('2026-03-31T13:15:00Z'));
    expect(session.lastTouchedAtUtc, DateTime.parse('2026-03-31T14:00:00Z'));
  });

  test('fromJson usa defaults seguros cuando faltan datos o son invalidos', () {
    final session = ActiveScanSession.fromJson({
      'createdAtUtc': 'fecha-invalida',
      'lastTouchedAtUtc': '',
      'pageCount': null,
    });

    expect(session.sessionId, isEmpty);
    expect(session.scannerName, isEmpty);
    expect(session.mode, isEmpty);
    expect(session.status, isEmpty);
    expect(session.pageCount, 0);
    expect(session.isRehydrated, isFalse);
    expect(
      session.createdAtUtc,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    expect(
      session.lastTouchedAtUtc,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test('modeLabel y deteccion de origen cubren adf flatbed y custom', () {
    final adfDuplex = ActiveScanSession.fromJson({
      'mode': 'adf-duplex',
    });
    final adfSimplex = ActiveScanSession.fromJson({
      'mode': 'adf-simplex',
    });
    final flatbed = ActiveScanSession.fromJson({
      'mode': 'flatbed-single',
    });
    final custom = ActiveScanSession.fromJson({
      'mode': 'custom-source',
    });
    final empty = ActiveScanSession.fromJson({});

    expect(adfDuplex.isAdf, isTrue);
    expect(adfDuplex.isFlatbed, isFalse);
    expect(adfDuplex.modeLabel, 'ADF duplex');

    expect(adfSimplex.isAdf, isTrue);
    expect(adfSimplex.modeLabel, 'ADF simplex');

    expect(flatbed.isAdf, isFalse);
    expect(flatbed.isFlatbed, isTrue);
    expect(flatbed.modeLabel, 'Cama plana');

    expect(custom.isAdf, isFalse);
    expect(custom.isFlatbed, isFalse);
    expect(custom.modeLabel, 'custom-source');

    expect(empty.modeLabel, 'sin dato');
  });

  test('isFinished distingue estados terminales y no terminales', () {
    expect(ActiveScanSession.fromJson({'status': 'completed'}).isFinished, isTrue);
    expect(ActiveScanSession.fromJson({'status': 'empty'}).isFinished, isTrue);
    expect(ActiveScanSession.fromJson({'status': 'canceled'}).isFinished, isTrue);
    expect(ActiveScanSession.fromJson({'status': 'error'}).isFinished, isTrue);
    expect(ActiveScanSession.fromJson({'status': 'running'}).isFinished, isFalse);
    expect(ActiveScanSession.fromJson({'status': 'queued'}).isFinished, isFalse);
  });

  test('isDormant e isStale responden al tiempo relativo real', () {
    final now = DateTime.now().toUtc();
    final recent = ActiveScanSession(
      sessionId: 'recent',
      createdAtUtc: now.subtract(const Duration(minutes: 2)),
      lastTouchedAtUtc: now.subtract(const Duration(minutes: 10)),
      scannerName: 'Canon',
      mode: 'adf-simplex',
      status: 'running',
      pageCount: 1,
      isRehydrated: false,
    );
    final dormant = ActiveScanSession(
      sessionId: 'dormant',
      createdAtUtc: now.subtract(const Duration(minutes: 30)),
      lastTouchedAtUtc: now.subtract(const Duration(minutes: 15)),
      scannerName: 'Canon',
      mode: 'adf-simplex',
      status: 'running',
      pageCount: 1,
      isRehydrated: false,
    );
    final stale = ActiveScanSession(
      sessionId: 'stale',
      createdAtUtc: now.subtract(const Duration(hours: 3)),
      lastTouchedAtUtc: now.subtract(const Duration(hours: 2)),
      scannerName: 'Canon',
      mode: 'adf-simplex',
      status: 'running',
      pageCount: 1,
      isRehydrated: false,
    );

    expect(recent.isDormant, isFalse);
    expect(recent.isStale, isFalse);
    expect(dormant.isDormant, isTrue);
    expect(dormant.isStale, isFalse);
    expect(stale.isDormant, isTrue);
    expect(stale.isStale, isTrue);
  });
}

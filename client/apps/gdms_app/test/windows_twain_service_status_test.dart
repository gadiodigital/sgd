import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/windows_twain_service_status.dart';

void main() {
  test('fromJson normaliza strings y parsea campos de sesiones', () {
    final status = WindowsTwainServiceStatus.fromJson({
      'application': ' windows-twain ',
      'version': ' 1.2.3 ',
      'baseUrl': ' http://127.0.0.1:43127 ',
      'runMode': ' service ',
      'startupLogPath': r' C:\logs\startup.log ',
      'scanner': {'message': ' 2 scanners ready '},
      'sessions': {
        'activeSessions': 4,
        'sessionsRootPath': r' C:\twain\sessions ',
        'lastCleanupAtUtc': '2026-03-31T12:30:00Z',
        'lastCleanupDeletedCount': 7,
      },
      'operations': [' scan-adf-duplex ', ' get-session '],
    });

    expect(status.application, 'windows-twain');
    expect(status.version, '1.2.3');
    expect(status.baseUrl, 'http://127.0.0.1:43127');
    expect(status.runMode, 'service');
    expect(status.startupLogPath, r'C:\logs\startup.log');
    expect(status.scannerSummary, '2 scanners ready');
    expect(status.activeSessions, 4);
    expect(status.sessionsRootPath, r'C:\twain\sessions');
    expect(status.lastCleanupAtUtc, DateTime.parse('2026-03-31T12:30:00Z'));
    expect(status.lastCleanupDeletedCount, 7);
    expect(status.operations, ['scan-adf-duplex', 'get-session']);
  });

  test('fromJson usa defaults seguros cuando faltan datos', () {
    final status = WindowsTwainServiceStatus.fromJson(const {});

    expect(status.application, isEmpty);
    expect(status.version, isEmpty);
    expect(status.baseUrl, isEmpty);
    expect(status.runMode, isEmpty);
    expect(status.startupLogPath, isEmpty);
    expect(status.scannerSummary, isEmpty);
    expect(status.activeSessions, 0);
    expect(status.sessionsRootPath, isEmpty);
    expect(status.lastCleanupAtUtc, isNull);
    expect(status.lastCleanupDeletedCount, 0);
    expect(status.operations, isEmpty);
  });

  test('scannerSummary toma string, message, status o transport', () {
    expect(
      WindowsTwainServiceStatus.fromJson({'scanner': ' ready '}).scannerSummary,
      'ready',
    );
    expect(
      WindowsTwainServiceStatus.fromJson({
        'scanner': {'status': ' idle '}
      }).scannerSummary,
      'idle',
    );
    expect(
      WindowsTwainServiceStatus.fromJson({
        'scanner': {'transport': ' twain '}
      }).scannerSummary,
      'twain',
    );
  });

  test('operations filtra por availability y soporta operationId o id', () {
    final status = WindowsTwainServiceStatus.fromJson({
      'operations': [
        {'operationId': 'scan-adf-duplex', 'availability': 'ready'},
        {'id': 'rotate-page', 'availability': ' READY '},
        {'operationId': 'merge-session', 'availability': 'blocked'},
        {'id': 'delete-page'},
      ],
    });

    expect(
      status.operations,
      ['scan-adf-duplex', 'rotate-page', 'delete-page'],
    );
    expect(status.supportsOperation('rotate-page'), isTrue);
    expect(status.supportsOperation('merge-session'), isFalse);
  });

  test('ignora sesiones invalidas y limpieza con fecha no parseable', () {
    final status = WindowsTwainServiceStatus.fromJson({
      'scanner': 42,
      'sessions': {
        'activeSessions': null,
        'sessionsRootPath': null,
        'lastCleanupAtUtc': 'not-a-date',
        'lastCleanupDeletedCount': null,
      },
      'operations': [1, {'availability': 'disabled', 'id': 'scan'}],
    });

    expect(status.scannerSummary, isEmpty);
    expect(status.activeSessions, 0);
    expect(status.sessionsRootPath, isEmpty);
    expect(status.lastCleanupAtUtc, isNull);
    expect(status.lastCleanupDeletedCount, 0);
    expect(status.operations, isEmpty);
  });
}

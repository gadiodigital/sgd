import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('detecta disponibilidad y lista escaneres', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response(
          jsonEncode(<String, Object?>{'status': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scanners') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'result': 'ok',
            'scanners': [
              {
                'id': 0,
                'name': 'EPSON DS-570W',
                'manufacturer': 'EPSON',
                'productFamily': 'Scanner',
                'twainVersion': '2.4',
                'isOpen': false,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'application': 'windows-twain',
            'version': '1.0.0',
            'baseUrl': 'http://127.0.0.1:43127',
            'runMode': 'headless',
            'startupLogPath': 'C:\\logs\\windows-twain.log',
            'scanner': <String, Object?>{'status': 'ready'},
            'sessions': <String, Object?>{
              'activeSessions': 2,
              'sessionsRootPath': 'C:\\twain\\sessions',
              'lastCleanupAtUtc': '2026-03-27T14:30:00Z',
              'lastCleanupDeletedCount': 1,
            },
            'operations': ['list-scanners', 'scan-adf-duplex'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scanners/discover') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'result': 'ok',
            'scanners': [
              {
                'id': 0,
                'name': 'EPSON DS-570W',
                'manufacturer': 'EPSON',
                'productFamily': 'Scanner',
                'twainVersion': '2.4',
                'isOpen': false,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(
          jsonEncode([
            <String, Object?>{
              'sessionId': 'session-1',
              'createdAtUtc': '2026-03-27T14:00:00Z',
              'lastTouchedAtUtc': '2026-03-27T14:10:00Z',
              'scannerName': 'EPSON DS-570W',
              'mode': 'adf-duplex',
              'status': 'completed',
              'pageCount': 3,
              'isRehydrated': true,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('not-found', 404);
    });

    final repository = WindowsTwainScanRepository(
      baseUrl: 'http://127.0.0.1:43127',
      httpClient: client,
    );

    expect(await repository.isAvailable(), isTrue);
    expect((await repository.listScanners()).single.name, 'EPSON DS-570W');
    expect(await repository.discoverScanners(), hasLength(1));

    final status = await repository.getStatus();
    final sessions = await repository.listSessions();
    expect(status.runMode, 'headless');
    expect(status.operations, ['list-scanners', 'scan-adf-duplex']);
    expect(status.activeSessions, 2);
    expect(status.sessionsRootPath, 'C:\\twain\\sessions');
    expect(status.lastCleanupAtUtc, DateTime.utc(2026, 3, 27, 14, 30));
    expect(status.lastCleanupDeletedCount, 1);
    expect(sessions, hasLength(1));
    expect(sessions.single.sessionId, 'session-1');
    expect(sessions.single.modeLabel, 'ADF duplex');
    expect(sessions.single.lastTouchedAtUtc, DateTime.utc(2026, 3, 27, 14, 10));
    expect(sessions.single.isRehydrated, isTrue);
  });

  test('ejecuta limpieza de sesiones locales', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/sessions/cleanup') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'application': 'windows-twain',
            'version': '1.0.0',
            'baseUrl': 'http://127.0.0.1:43127',
            'runMode': 'headless',
            'startupLogPath': 'C:\\logs\\windows-twain.log',
            'scanner': <String, Object?>{'status': 'ready'},
            'sessions': <String, Object?>{
              'activeSessions': 0,
              'sessionsRootPath': 'C:\\twain\\sessions',
              'lastCleanupAtUtc': '2026-03-27T15:45:00Z',
              'lastCleanupDeletedCount': 3,
            },
            'operations': ['list-scanners', 'scan-flatbed-single'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('not-found', 404);
    });

    final repository = WindowsTwainScanRepository(
      baseUrl: 'http://127.0.0.1:43127',
      httpClient: client,
    );

    final status = await repository.cleanupSessions();
    expect(status.activeSessions, 0);
    expect(status.lastCleanupAtUtc, DateTime.utc(2026, 3, 27, 15, 45));
    expect(status.lastCleanupDeletedCount, 3);
    expect(status.operations, ['list-scanners', 'scan-flatbed-single']);
  });

  test('vacía las sesiones activas del host local', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/sessions' && request.method == 'DELETE') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'application': 'windows-twain',
            'version': '1.0.0',
            'baseUrl': 'http://127.0.0.1:43127',
            'runMode': 'headless',
            'startupLogPath': 'C:\\logs\\windows-twain.log',
            'scanner': <String, Object?>{'status': 'ready'},
            'sessions': <String, Object?>{
              'activeSessions': 0,
              'sessionsRootPath': 'C:\\twain\\sessions',
              'lastCleanupAtUtc': '2026-03-27T15:45:00Z',
              'lastCleanupDeletedCount': 0,
            },
            'operations': ['list-scanners', 'scan-flatbed-single'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('not-found', 404);
    });

    final repository = WindowsTwainScanRepository(
      baseUrl: 'http://127.0.0.1:43127',
      httpClient: client,
    );

    final status = await repository.clearActiveSessions();
    expect(status.activeSessions, 0);
    expect(status.lastCleanupDeletedCount, 0);
    expect(status.operations, ['list-scanners', 'scan-flatbed-single']);
  });

  test('vacía sesiones inactivas y rehidratadas del host local', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/sessions/stale' &&
          request.method == 'DELETE') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'application': 'windows-twain',
            'version': '1.0.0',
            'baseUrl': 'http://127.0.0.1:43127',
            'runMode': 'headless',
            'startupLogPath': 'C:\\logs\\windows-twain.log',
            'scanner': <String, Object?>{'status': 'ready'},
            'sessions': <String, Object?>{
              'activeSessions': 1,
              'sessionsRootPath': 'C:\\twain\\sessions',
              'lastCleanupAtUtc': '2026-03-27T15:45:00Z',
              'lastCleanupDeletedCount': 0,
            },
            'operations': ['list-scanners', 'scan-flatbed-single'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/sessions/rehydrated' &&
          request.method == 'DELETE') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'application': 'windows-twain',
            'version': '1.0.0',
            'baseUrl': 'http://127.0.0.1:43127',
            'runMode': 'headless',
            'startupLogPath': 'C:\\logs\\windows-twain.log',
            'scanner': <String, Object?>{'status': 'ready'},
            'sessions': <String, Object?>{
              'activeSessions': 0,
              'sessionsRootPath': 'C:\\twain\\sessions',
              'lastCleanupAtUtc': '2026-03-27T15:45:00Z',
              'lastCleanupDeletedCount': 0,
            },
            'operations': ['list-scanners', 'scan-flatbed-single'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('not-found', 404);
    });

    final repository = WindowsTwainScanRepository(
      baseUrl: 'http://127.0.0.1:43127',
      httpClient: client,
    );

    final staleStatus = await repository.clearStaleSessions();
    final rehydratedStatus = await repository.clearRehydratedSessions();
    expect(staleStatus.activeSessions, 1);
    expect(rehydratedStatus.activeSessions, 0);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_host_support.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    DocumentScanPreferences.save(DocumentScanPreferences.defaults);
  });

  DocumentScanViewModel buildViewModel(MockClient client) {
    return DocumentScanViewModel(
      WindowsTwainScanRepository(
        baseUrl: 'http://127.0.0.1:43127',
        httpClient: client,
      ),
    );
  }

  test('refreshHostSnapshot carga status sesiones y scanners detectados', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [
              {'id': 'scan-adf-simplex', 'availability': 'ready'},
              {'id': 'scan-flatbed-single', 'availability': 'ready'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(
          jsonEncode([
            {
              'sessionId': 's-1',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
              'scannerName': 'Canon DR',
              'mode': 'adf-simplex',
              'status': 'running',
              'pageCount': 2,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scanners') {
        return http.Response(
          jsonEncode({
            'scanners': [
              {
                'id': 1,
                'name': 'Canon DR',
                'manufacturer': 'Canon',
                'productFamily': 'DR',
                'twainVersion': '2.4',
                'isOpen': false,
              },
            ],
          }),
          200,
        );
      }

      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);

    await DocumentScanViewModelHostSupport.refreshHostSnapshot(
      vm,
      forceDiscover: false,
      preserveMessage: false,
    );

    expect(vm.serviceAvailable, isTrue);
    expect(vm.serviceStatus, isNotNull);
    expect(vm.scanners, hasLength(1));
    expect(vm.selectedScanner?.name, 'Canon DR');
    expect(vm.activeSessions, hasLength(1));
    expect(vm.source, ScanSource.adf);
    expect(vm.message, 'El host actual no publica duplex. Se uso simplex.');
  });

  test('refreshHostSnapshot en servicio caido limpia estado y deja mensaje', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return http.Response('down', 503);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setSelectedScanner(null);

    await DocumentScanViewModelHostSupport.refreshHostSnapshot(
      vm,
      forceDiscover: false,
      preserveMessage: false,
    );

    expect(vm.serviceAvailable, isFalse);
    expect(vm.serviceStatus, isNull);
    expect(vm.activeSessions, isEmpty);
    expect(
      vm.message,
      'El servicio windows-twain no responde en http://127.0.0.1:43127.',
    );
  });

  test('refreshHostSnapshot recompone estado cuando el host vuelve a responder', () async {
    var hostAvailable = false;

    final client = MockClient((request) async {
      if (request.url.path == '/health') {
        return hostAvailable
            ? http.Response(jsonEncode({'status': 'ok'}), 200)
            : http.Response('down', 503);
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [
              {'id': 'scan-adf-duplex', 'availability': 'ready'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(
          jsonEncode([
            {
              'sessionId': 's-recovered',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:10:00Z',
              'scannerName': 'Brother ADS',
              'mode': 'adf-duplex',
              'status': 'completed',
              'pageCount': 3,
              'isRehydrated': true,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scanners') {
        return http.Response(
          jsonEncode({
            'scanners': [
              {
                'id': 7,
                'name': 'Brother ADS',
                'manufacturer': 'Brother',
                'productFamily': 'ADS',
                'twainVersion': '2.4',
                'isOpen': false,
              },
            ],
          }),
          200,
        );
      }

      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);

    await DocumentScanViewModelHostSupport.refreshHostSnapshot(
      vm,
      forceDiscover: false,
      preserveMessage: false,
    );

    expect(vm.serviceAvailable, isFalse);
    expect(vm.serviceStatus, isNull);
    expect(vm.activeSessions, isEmpty);
    expect(
      vm.message,
      'El servicio windows-twain no responde en http://127.0.0.1:43127.',
    );

    hostAvailable = true;

    await DocumentScanViewModelHostSupport.refreshHostSnapshot(
      vm,
      forceDiscover: false,
      preserveMessage: false,
    );

    expect(vm.serviceAvailable, isTrue);
    expect(vm.serviceStatus, isNotNull);
    expect(vm.scanners, hasLength(1));
    expect(vm.selectedScanner?.name, 'Brother ADS');
    expect(vm.activeSessions, hasLength(1));
    expect(vm.activeSessions.single.sessionId, 's-recovered');
    expect(vm.activeSessions.single.isRehydrated, isTrue);
    expect(vm.message, 'Selecciona el escaner y dispara el escaneo.');
  });

  test('clearActiveSessions limpia scan actual y referencia persistida', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/sessions' && request.method == 'DELETE') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'activeSessions': 0,
            'operations': [],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions' && request.method == 'GET') {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setLastKnownSessionId('s-1');
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [1],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelHostSupport.clearActiveSessions(vm);

    expect(vm.activeSessions, isEmpty);
    expect(vm.lastKnownSessionId, isNull);
    expect(vm.lastScannedFile, isNull);
    expect(
      vm.message,
      'Se vaciaron las sesiones activas del host local.',
    );
    expect(DocumentScanPreferences.current.lastSessionId, isNull);
  });
}

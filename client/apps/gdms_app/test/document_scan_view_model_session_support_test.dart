import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_session_support.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
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

  ScannerDevice buildScanner(String name) {
    return ScannerDevice(
      id: 1,
      name: name,
      manufacturer: 'Canon',
      productFamily: 'DR',
      twainVersion: '2.4',
      isOpen: false,
    );
  }

  test('resumeLastSession restaura pdf preview y settings de la sesion', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-9') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-9',
            'status': 'completed',
            'mode': 'flatbed-single',
            'scannerName': 'Canon DR',
            'pageCount': 2,
            'settings': {
              'dpi': 200,
              'pixelType': 'gray',
              'discardBlankPages': 'off',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-9/pdf') {
        return http.Response.bytes([1, 2, 3, 4], 200);
      }
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
              {'id': 'get-session', 'availability': 'ready'},
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
              'sessionId': 's-9',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
              'scannerName': 'Canon DR',
              'mode': 'flatbed-single',
              'status': 'completed',
              'pageCount': 2,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path ==
          '/api/scans/s-9/pages/1/preview') {
        return http.Response.bytes(
          const [
            137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0,
            0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73,
            68, 65, 84, 120, 156, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254,
            167, 53, 129, 132, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
          ],
          200,
        );
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setScanners([buildScanner('Canon DR')]);
    vm.setLastKnownSessionId('s-9');

    await DocumentScanViewModelSessionSupport.resumeLastSession(vm);

    expect(vm.lastScannedFile?.sessionId, 's-9');
    expect(vm.lastScannedFile?.bytes, [1, 2, 3, 4]);
    expect(vm.previewBytes, isNotNull);
    expect(vm.source, ScanSource.flatbed);
    expect(vm.dpi, 200);
    expect(vm.pixelType, 'gray');
    expect(vm.discardBlankPages, 'off');
    expect(vm.selectedScanner?.name, 'Canon DR');
    expect(vm.message, 'Sesion s-9 reanudada con 2 pagina(s).');
  });

  test('discardSessionById limpia session conocida y scan actual si coincide', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-1' && request.method == 'DELETE') {
        return http.Response('', 204);
      }
      if (request.url.path == '/health') {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
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
        bytes: [1, 2],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSessionSupport.discardSessionById(vm, 's-1');

    expect(vm.lastKnownSessionId, isNull);
    expect(vm.lastScannedFile, isNull);
    expect(vm.activeSessions, isEmpty);
    expect(vm.message, 'Sesion s-1 descartada del host local.');
  });

  test('resumeLastSession limpia referencia si la sesion ya no existe', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-missing') {
        return http.Response(
          jsonEncode({'message': 'missing'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/health') {
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [{'id': 'get-session', 'availability': 'ready'}],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(jsonEncode([]), 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setLastKnownSessionId('s-missing');

    await DocumentScanViewModelSessionSupport.resumeLastSession(vm);

    expect(vm.lastKnownSessionId, isNull);
    expect(
      vm.message,
      'La ultima sesion local ya no esta disponible. Se limpio la referencia.',
    );
  });
}

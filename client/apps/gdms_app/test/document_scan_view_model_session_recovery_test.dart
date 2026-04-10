import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_session_support.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
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

  test('refreshSession conserva estado local e informa error si el host cae durante la operacion', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-live') {
        throw http.ClientException('connection refused', request.url);
      }
      if (request.url.path == '/api/health' || request.url.path == '/health') {
        throw http.ClientException('connection refused', request.url);
      }
      if (request.url.path == '/api/status' || request.url.path == '/api/sessions') {
        throw http.ClientException('connection refused', request.url);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setServiceAvailable(true);
    vm.setActiveSessions(const []);
    vm.setCurrentPreviewPage(2);
    vm.setPreviewBytes([9, 9, 9]);
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-live',
        fileName: 'scan.pdf',
        bytes: [1, 2, 3],
        pageCount: 3,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSessionSupport.refreshSession(vm);

    expect(vm.lastScannedFile?.sessionId, 's-live');
    expect(vm.lastScannedFile?.pageCount, 3);
    expect(vm.previewBytes, [9, 9, 9]);
    expect(vm.currentPreviewPage, 2);
    expect(vm.serviceAvailable, isFalse);
    expect(vm.serviceStatus, isNull);
    expect(vm.activeSessions, isEmpty);
    expect(
      vm.message,
      'No se pudo conectar con windows-twain en http://127.0.0.1:43127.',
    );
  });

  test('refreshSession recompone estado operativo cuando el host vuelve durante una sesion activa', () async {
    var hostAvailable = false;

    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-live') {
        if (!hostAvailable) {
          throw http.ClientException('connection refused', request.url);
        }
        return http.Response(
          jsonEncode({
            'sessionId': 's-live',
            'status': 'completed',
            'mode': 'adf-duplex',
            'scannerName': 'Canon DR',
            'pageCount': 2,
            'settings': {
              'dpi': 300,
              'pixelType': 'color',
              'discardBlankPages': 'auto',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/health') {
        if (!hostAvailable) {
          throw http.ClientException('connection refused', request.url);
        }
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }
      if (request.url.path == '/api/status') {
        if (!hostAvailable) {
          throw http.ClientException('connection refused', request.url);
        }
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [
              {'id': 'get-session', 'availability': 'ready'},
              {'id': 'scan-adf-duplex', 'availability': 'ready'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        if (!hostAvailable) {
          throw http.ClientException('connection refused', request.url);
        }
        return http.Response(
          jsonEncode([
            {
              'sessionId': 's-live',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:10:00Z',
              'scannerName': 'Canon DR',
              'mode': 'adf-duplex',
              'status': 'completed',
              'pageCount': 2,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-live/pages/1/preview') {
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
    vm.setCurrentPreviewPage(1);
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-live',
        fileName: 'scan.pdf',
        bytes: [1, 2, 3],
        pageCount: 3,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSessionSupport.refreshSession(vm);

    expect(vm.serviceAvailable, isFalse);
    expect(vm.activeSessions, isEmpty);

    hostAvailable = true;

    await DocumentScanViewModelSessionSupport.refreshSession(vm);

    expect(vm.serviceAvailable, isTrue);
    expect(vm.serviceStatus, isNotNull);
    expect(vm.activeSessions, hasLength(1));
    expect(vm.activeSessions.single.sessionId, 's-live');
    expect(vm.lastScannedFile?.pageCount, 2);
    expect(vm.previewBytes, isNotNull);
    expect(
      vm.message,
      'Sesion s-live refrescada: 2 pagina(s), estado completed.',
    );
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_support.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const validPngBytes = <int>[
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1,
    0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
    120, 156, 99, 248, 255, 255, 63, 0, 5, 254, 2, 254, 167, 53, 129, 132, 0,
    0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
  ];

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

  ScannerDevice buildScanner() {
    return const ScannerDevice(
      id: 1,
      name: 'Canon DR',
      manufacturer: 'Canon',
      productFamily: 'DR',
      twainVersion: '2.4',
      isOpen: false,
    );
  }

  test('deleteCurrentPage descarta la sesion cuando queda vacia', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-1/pages/1' &&
          request.method == 'DELETE') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-1',
            'status': 'empty',
            'pageCount': 0,
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-1' && request.method == 'DELETE') {
        return http.Response('', 204);
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
        bytes: [1],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSupport.deleteCurrentPage(vm);

    expect(vm.lastScannedFile, isNull);
    expect(vm.lastKnownSessionId, isNull);
    expect(vm.activeSessions, isEmpty);
    expect(vm.message, 'La sesion quedo vacia y se descarto del host local.');
  });

  test('appendAnotherScan fusiona sesiones refresca pdf y mueve preview al final', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/adf/duplex') {
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 's-extra',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 2,
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-extra/pdf') {
        return http.Response.bytes(
          [9, 9],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="s-extra.pdf"',
          },
        );
      }
      if (request.url.path == '/api/scans/s-main/merge') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-main',
            'status': 'completed',
            'pageCount': 4,
          }),
          200,
        );
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [
              {'id': 'merge-session', 'availability': 'ready'},
              {'id': 'get-session', 'availability': 'ready'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(
          jsonEncode([
            {
              'sessionId': 's-main',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
              'scannerName': 'Canon DR',
              'mode': 'adf-duplex',
              'status': 'completed',
              'pageCount': 4,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-main') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-main',
            'status': 'completed',
            'mode': 'adf-duplex',
            'scannerName': 'Canon DR',
            'pageCount': 4,
            'settings': {
              'dpi': 300,
              'pixelType': 'color',
              'discardBlankPages': 'auto',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-main/pdf') {
        return http.Response.bytes([1, 2, 3, 4, 5], 200);
      }
      if (request.url.path == '/api/scans/s-main/pages/4/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setSelectedScanner(buildScanner());
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-main',
        fileName: 'main.pdf',
        bytes: [1],
        pageCount: 2,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSupport.appendAnotherScan(vm);

    expect(vm.lastScannedFile?.sessionId, 's-main');
    expect(vm.lastScannedFile?.pageCount, 4);
    expect(vm.lastScannedFile?.bytes, [1, 2, 3, 4, 5]);
    expect(vm.currentPreviewPage, 4);
    expect(vm.previewBytes, validPngBytes);
    expect(
      vm.message,
      'Se agregaron 2 paginas desde ADF. Total actual: 4.',
    );
  });
}

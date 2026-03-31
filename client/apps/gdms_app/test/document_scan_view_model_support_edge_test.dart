import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_support.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
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

  test('deleteCurrentPage parcial refresca preview pdf y contador', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-2/pages/3' &&
          request.method == 'DELETE') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-2',
            'status': 'completed',
            'pageCount': 2,
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-2') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-2',
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
      if (request.url.path == '/api/scans/s-2/pdf') {
        return http.Response.bytes([6, 7, 8], 200);
      }
      if (request.url.path == '/api/scans/s-2/pages/2/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setCurrentPreviewPage(3);
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-2',
        fileName: 'scan.pdf',
        bytes: [1],
        pageCount: 3,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSupport.deleteCurrentPage(vm);

    expect(vm.lastScannedFile?.pageCount, 2);
    expect(vm.lastScannedFile?.bytes, [6, 7, 8]);
    expect(vm.currentPreviewPage, 2);
    expect(vm.previewBytes, validPngBytes);
    expect(vm.message, 'Pagina eliminada. Quedan 2 pagina(s).');
  });

  test('insertAnotherScanBeforeCurrentPage usa mensaje y pagina inicial correctos', () async {
    late Map<String, dynamic> mergePayload;
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/flatbed/single') {
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 's-extra',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 1,
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/s-extra/pdf') {
        return http.Response.bytes(
          [4, 4],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="s-extra.pdf"',
          },
        );
      }
      if (request.url.path == '/api/scans/s-main/merge') {
        mergePayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'sessionId': 's-main',
            'status': 'completed',
            'pageCount': 3,
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
              {'id': 'scan-flatbed-single', 'availability': 'ready'},
            ],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(jsonEncode(const []), 200);
      }
      if (request.url.path == '/api/scans/s-main') {
        return http.Response(
          jsonEncode({
            'sessionId': 's-main',
            'status': 'completed',
            'mode': 'flatbed-single',
            'scannerName': 'Canon DR',
            'pageCount': 3,
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
        return http.Response.bytes([1, 2, 3], 200);
      }
      if (request.url.path == '/api/scans/s-main/pages/1/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setSelectedScanner(buildScanner());
    vm.setSource(ScanSource.flatbed, persist: false);
    vm.setCurrentPreviewPage(1);
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-main',
        fileName: 'main.pdf',
        bytes: [1],
        pageCount: 2,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSupport.insertAnotherScanBeforeCurrentPage(vm);

    expect(mergePayload, {
      'sourceSessionId': 's-extra',
      'insertAfterPageNumber': 0,
    });
    expect(vm.currentPreviewPage, 1);
    expect(
      vm.message,
      'Se insertaron 1 pagina desde cama plana antes de la pagina actual. Total actual: 3.',
    );
  });

  test('loadPreview deja preview nulo cuando el servicio no puede renderizarla', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-1/pages/1/preview') {
        return http.Response(
          jsonEncode({'message': 'preview-error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setPreviewBytes([1, 2, 3]);
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [1],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    await DocumentScanViewModelSupport.loadPreview(vm);

    expect(vm.previewBytes, isNull);
  });
}

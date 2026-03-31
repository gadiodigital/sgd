import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_preferences.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model_support.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/infrastructure/api/api_exception.dart';
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

  test('scan informa error temprano cuando no hay scanner seleccionado', () async {
    final client = MockClient((request) async => http.Response('not-found', 404));
    final vm = buildViewModel(client);

    final scannedFile = await vm.scan();

    expect(scannedFile, isNull);
    expect(vm.message, 'Selecciona un escaner antes de iniciar el escaneo.');
  });

  test('scan exitoso actualiza archivo sesion preview y mensaje', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/adf/duplex') {
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 'session-123',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 2,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/session-123/pdf') {
        return http.Response.bytes(
          [1, 2, 3, 4],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="session-123.pdf"',
          },
        );
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [
              {'id': 'scan-adf-duplex', 'availability': 'ready'},
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
              'sessionId': 'session-123',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
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
      if (request.url.path == '/api/scans/session-123') {
        return http.Response(
          jsonEncode({
            'sessionId': 'session-123',
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
      if (request.url.path == '/api/scans/session-123/pages/1/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setSelectedScanner(buildScanner());

    final scannedFile = await vm.scan();

    expect(scannedFile, isNotNull);
    expect(vm.lastScannedFile?.sessionId, 'session-123');
    expect(vm.lastKnownSessionId, 'session-123');
    expect(vm.sessionDetails?.pageCount, 2);
    expect(vm.previewBytes, validPngBytes);
    expect(vm.activeSessions, hasLength(1));
    expect(vm.message, 'Escaneo ADF completado con 2 pagina(s).');
  });

  test('scan mapea errores de conexion al servicio local', () async {
    final client = MockClient((request) async {
      throw http.ClientException('connection refused');
    });
    final vm = buildViewModel(client);
    vm.setSelectedScanner(buildScanner());

    final scannedFile = await vm.scan();

    expect(scannedFile, isNull);
    expect(
      vm.message,
      'No se pudo conectar con windows-twain en http://127.0.0.1:43127.',
    );
  });

  test('scan flatbed exitoso actualiza fuente y mensaje especifico', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/flatbed/single') {
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 'flatbed-001',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/flatbed-001/pdf') {
        return http.Response.bytes(
          [7, 8, 9],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="flatbed-001.pdf"',
          },
        );
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': [
              {'id': 'scan-flatbed-single', 'availability': 'ready'},
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
              'sessionId': 'flatbed-001',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
              'scannerName': 'Canon DR',
              'mode': 'flatbed-single',
              'status': 'completed',
              'pageCount': 1,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scans/flatbed-001') {
        return http.Response(
          jsonEncode({
            'sessionId': 'flatbed-001',
            'status': 'completed',
            'mode': 'flatbed-single',
            'scannerName': 'Canon DR',
            'pageCount': 1,
            'settings': {
              'dpi': 200,
              'pixelType': 'gray',
              'discardBlankPages': 'off',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/flatbed-001/pages/1/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });

    final vm = buildViewModel(client);
    vm.setSelectedScanner(buildScanner());
    vm.setSource(ScanSource.flatbed, persist: false);

    final scannedFile = await vm.scan();

    expect(scannedFile, isNotNull);
    expect(vm.lastScannedFile?.sessionId, 'flatbed-001');
    expect(vm.source, ScanSource.flatbed);
    expect(vm.sessionDetails?.dpi, 200);
    expect(vm.sessionDetails?.pixelType, 'gray');
    expect(vm.sessionDetails?.discardBlankPages, 'off');
    expect(vm.message, 'Escaneo flatbed completado con 1 pagina(s).');
  });

  test('scan usa mensaje de ApiException del servicio', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/adf/duplex') {
        return http.Response(
          jsonEncode({'message': 'ADF ocupado'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setSelectedScanner(buildScanner());

    final scannedFile = await vm.scan();

    expect(scannedFile, isNull);
    expect(vm.message, 'ADF ocupado');
  });

  test('mapError cubre ApiException y fallback generico', () {
    expect(
      DocumentScanViewModelSupport.mapError(
        'http://127.0.0.1:43127',
        const ApiException('Host devolvio error'),
      ),
      'Host devolvio error',
    );
    expect(
      DocumentScanViewModelSupport.mapError(
        'http://127.0.0.1:43127',
        StateError('boom'),
      ),
      'No se pudo completar el escaneo con el servicio local.',
    );
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('escanea ADF y descarga el pdf final', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/adf/duplex') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'result': 'ok',
            'sessionId': 'session-123',
            'status': 'completed',
            'scannerName': 'EPSON DS-570W',
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
      if (request.url.path == '/api/scans/session-123') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'sessionId': 'session-123',
            'status': 'completed',
            'mode': 'adf-duplex',
            'scannerName': 'EPSON DS-570W',
            'pageCount': 2,
            'settings': <String, Object?>{
              'dpi': 300.0,
              'pixelType': 'color',
              'discardBlankPages': 'auto',
            },
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

    final scannedFile = await repository.scanAdf(
      duplex: true,
      scannerId: 0,
      scannerName: 'EPSON DS-570W',
    );

    expect(scannedFile.sessionId, 'session-123');
    expect(scannedFile.fileName, 'session-123.pdf');
    expect(scannedFile.pageCount, 2);
    expect(scannedFile.bytes, [1, 2, 3, 4]);

    final session = await repository.getSession('session-123');
    expect(session.mode, 'adf-duplex');
    expect(session.dpi, 300);
  });

  test('ajusta y elimina paginas de una sesion', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/session-123/pages/1/adjust') {
        return http.Response(
          jsonEncode(<String, Object?>{'result': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/session-123/pages/2') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'sessionId': 'session-123',
            'status': 'completed',
            'pageCount': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/session-123/pages/1/move') {
        return http.Response(
          jsonEncode(<String, Object?>{'result': 'ok'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/session-123/pdf') {
        return http.Response.bytes([9, 8, 7], 200);
      }

      return http.Response('not-found', 404);
    });

    final repository = WindowsTwainScanRepository(
      baseUrl: 'http://127.0.0.1:43127',
      httpClient: client,
    );

    await repository.adjustPage(
      'session-123',
      1,
      brightness: 10,
      contrast: -10,
    );
    await repository.movePage('session-123', 1, targetPageNumber: 2);

    final snapshot = await repository.deletePage('session-123', 2);
    expect(snapshot.pageCount, 1);
    expect(snapshot.isEmpty, isFalse);

    final pdfBytes = await repository.downloadPdf('session-123');
    expect(pdfBytes, [9, 8, 7]);
  });

  test('fusiona otra sesion en una posicion especifica', () async {
    late Map<String, dynamic> mergePayload;
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/session-123/merge') {
        mergePayload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, Object?>{
            'sessionId': 'session-123',
            'status': 'completed',
            'pageCount': 5,
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

    final snapshot = await repository.mergeSession(
      'session-123',
      'session-extra',
      insertAfterPageNumber: 0,
    );

    expect(mergePayload, <String, dynamic>{
      'sourceSessionId': 'session-extra',
      'insertAfterPageNumber': 0,
    });
    expect(snapshot.pageCount, 5);
  });

  test('escanea flatbed simple y descarga el pdf final', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/flatbed/single') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'result': 'ok',
            'sessionId': 'flatbed-001',
            'status': 'completed',
            'scannerName': 'Kodak i3400',
            'pageCount': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/flatbed-001/pdf') {
        return http.Response.bytes(
          [5, 4, 3, 2],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="flatbed-001.pdf"',
          },
        );
      }

      return http.Response('not-found', 404);
    });

    final repository = WindowsTwainScanRepository(
      baseUrl: 'http://127.0.0.1:43127',
      httpClient: client,
    );

    final scannedFile = await repository.scanFlatbedSingle(
      scannerId: 1,
      scannerName: 'Kodak i3400',
      dpi: 300,
      pixelType: 'gray',
    );

    expect(scannedFile.sessionId, 'flatbed-001');
    expect(scannedFile.pageCount, 1);
    expect(scannedFile.fileName, 'flatbed-001.pdf');
    expect(scannedFile.bytes, [5, 4, 3, 2]);
  });
}

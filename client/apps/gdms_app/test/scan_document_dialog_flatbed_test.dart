import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_dialog.dart';
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

  Widget buildDialogHarness({
    required DocumentScanViewModel viewModel,
    required ValueChanged<Object?> onResult,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog<Object?>(
                context: context,
                builder: (_) => ScanDocumentDialog(
                  viewModel: viewModel,
                  autoStart: false,
                ),
              ).then(onResult);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('dialogo ejecuta escaneo flatbed y adapta labels de preview', (
    tester,
  ) async {
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
          [4, 5, 6],
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
              {'id': 'merge-session', 'availability': 'ready'},
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
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setSource(ScanSource.flatbed, persist: false);

    await tester.pumpWidget(buildDialogHarness(viewModel: vm, onResult: (_) {}));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Escanear'));
    await tester.tap(find.widgetWithText(FilledButton, 'Escanear'));
    await tester.pumpAndSettle();

    expect(find.text('Escaneo flatbed completado con 1 pagina(s).'), findsOneWidget);
    expect(find.text('Agregar hoja'), findsOneWidget);
    expect(find.text('Insertar hoja antes'), findsOneWidget);
    expect(find.text('Insertar hoja despues'), findsOneWidget);
    expect(find.textContaining('flatbed-001.pdf'), findsOneWidget);
  });

  testWidgets('usar escaneo devuelve el archivo nuevo despues de una captura flatbed', (
    tester,
  ) async {
    var deletedSessions = 0;
    Object? dialogResult;
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/flatbed/single') {
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 'flatbed-002',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/flatbed-002/pdf') {
        return http.Response.bytes(
          [8, 8, 8],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="flatbed-002.pdf"',
          },
        );
      }
      if (request.url.path == '/api/scans/flatbed-002' &&
          request.method == 'DELETE') {
        deletedSessions += 1;
        return http.Response('', 204);
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
        return http.Response(jsonEncode(const []), 200);
      }
      if (request.url.path == '/api/scans/flatbed-002' &&
          request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'sessionId': 'flatbed-002',
            'status': 'completed',
            'mode': 'flatbed-single',
            'scannerName': 'Canon DR',
            'pageCount': 1,
            'settings': {
              'dpi': 300,
              'pixelType': 'color',
              'discardBlankPages': 'auto',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/scans/flatbed-002/pages/1/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setSource(ScanSource.flatbed, persist: false);

    await tester.pumpWidget(
      buildDialogHarness(viewModel: vm, onResult: (value) => dialogResult = value),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Escanear'));
    await tester.tap(find.widgetWithText(FilledButton, 'Escanear'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Usar escaneo'));
    await tester.tap(find.widgetWithText(FilledButton, 'Usar escaneo'));
    await tester.pumpAndSettle();

    expect(deletedSessions, 1);
    final result = dialogResult as ScannedDocumentFile;
    expect(result.sessionId, 'flatbed-002');
    expect(result.fileName, 'flatbed-002.pdf');
  });
}

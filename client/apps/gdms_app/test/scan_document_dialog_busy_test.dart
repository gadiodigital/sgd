import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
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

  Widget buildDialogHarness(DocumentScanViewModel viewModel) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog<void>(
                context: context,
                builder: (_) => ScanDocumentDialog(
                  viewModel: viewModel,
                  autoStart: false,
                ),
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  testWidgets('dialogo muestra estado busy mientras el escaneo esta en curso', (
    tester,
  ) async {
    final scanGate = Completer<void>();
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/adf/duplex') {
        await scanGate.future;
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 'session-busy',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 1,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/session-busy/pdf') {
        return http.Response.bytes(
          [1, 2],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="session-busy.pdf"',
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
              'sessionId': 'session-busy',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
              'scannerName': 'Canon DR',
              'mode': 'adf-duplex',
              'status': 'completed',
              'pageCount': 1,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scans/session-busy') {
        return http.Response(
          jsonEncode({
            'sessionId': 'session-busy',
            'status': 'completed',
            'mode': 'adf-duplex',
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
      if (request.url.path == '/api/scans/session-busy/pages/1/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());

    await tester.pumpWidget(buildDialogHarness(vm));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Escanear'));
    await tester.tap(find.widgetWithText(FilledButton, 'Escanear'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.widgetWithText(TextButton, 'Cancelar'))
          .onPressed,
      isNull,
    );

    scanGate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Escaneo ADF completado con 1 pagina(s).'), findsOneWidget);
  });

  testWidgets('escanear de nuevo reemplaza la captura previa con la nueva sesion', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/adf/duplex') {
        return http.Response(
          jsonEncode({
            'result': 'ok',
            'sessionId': 'session-new',
            'status': 'completed',
            'scannerName': 'Canon DR',
            'pageCount': 3,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/scans/session-new/pdf') {
        return http.Response.bytes(
          [7, 8, 9],
          200,
          headers: {
            'content-type': 'application/pdf',
            'content-disposition': 'attachment; filename="session-new.pdf"',
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
              'sessionId': 'session-new',
              'createdAtUtc': '2026-03-31T10:00:00Z',
              'lastTouchedAtUtc': '2026-03-31T10:05:00Z',
              'scannerName': 'Canon DR',
              'mode': 'adf-duplex',
              'status': 'completed',
              'pageCount': 3,
              'isRehydrated': false,
            },
          ]),
          200,
        );
      }
      if (request.url.path == '/api/scans/session-new') {
        return http.Response(
          jsonEncode({
            'sessionId': 'session-new',
            'status': 'completed',
            'mode': 'adf-duplex',
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
      if (request.url.path == '/api/scans/session-new/pages/1/preview') {
        return http.Response.bytes(validPngBytes, 200);
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setLastKnownSessionId('session-old');
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 'session-old',
        fileName: 'session-old.pdf',
        bytes: [1],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    await tester.pumpWidget(buildDialogHarness(vm));
    await tester.pumpAndSettle();

    expect(find.textContaining('session-old.pdf'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Escanear de nuevo'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Escanear de nuevo'));
    await tester.pumpAndSettle();

    expect(vm.lastScannedFile?.sessionId, 'session-new');
    expect(vm.lastScannedFile?.pageCount, 3);
    expect(find.textContaining('session-new.pdf'), findsOneWidget);
    expect(find.textContaining('session-old.pdf'), findsNothing);
    expect(find.text('Escaneo ADF completado con 3 pagina(s).'), findsOneWidget);
  });
}

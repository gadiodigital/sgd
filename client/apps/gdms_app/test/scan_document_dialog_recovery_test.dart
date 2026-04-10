import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
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

  testWidgets(
    'dialogo reintenta desde la preview y recompone la sesion activa cuando vuelve el host',
    (tester) async {
      var refreshed = false;
      final client = MockClient((request) async {
        if (request.url.path == '/api/scans/s-live') {
          refreshed = true;
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
        if (request.url.path == '/api/status') {
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
          return http.Response.bytes(validPngBytes, 200);
        }
        return http.Response('not-found', 404);
      });

      final vm = buildViewModel(client);
      vm.setCurrentPreviewPage(1);
      vm.setServiceAvailable(false);
      vm.setLastScannedFile(
        const ScannedDocumentFile(
          sessionId: 's-live',
          fileName: 'scan.pdf',
          bytes: [1, 2, 3],
          pageCount: 3,
          scannerName: 'Canon DR',
        ),
      );

      await tester.pumpWidget(buildDialogHarness(vm));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar conexión'), findsOneWidget);
      expect(
        find.textContaining('Puedes reintentar la conexión'),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Reintentar conexión'),
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Reintentar conexión'),
      );
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
      expect(vm.serviceAvailable, isTrue);
      expect(vm.activeSessions, hasLength(1));
      expect(vm.lastScannedFile?.pageCount, 2);
      expect(find.text('Releer sesión'), findsOneWidget);
      expect(find.textContaining('Puedes reintentar la conexión'), findsNothing);
      expect(
        find.text('Sesion s-live refrescada: 2 pagina(s), estado completed.'),
        findsOneWidget,
      );
    },
  );
}

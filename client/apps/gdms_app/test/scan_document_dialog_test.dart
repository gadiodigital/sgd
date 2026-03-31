import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/application/document_scan_view_model.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/infrastructure/repositories/windows_twain_scan_repository.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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

  testWidgets('dialogo sin escaneo activo muestra accion Escanear deshabilitada', (
    tester,
  ) async {
    final vm = buildViewModel(
      MockClient((request) async => http.Response('not-found', 404)),
    );

    await tester.pumpWidget(
      buildDialogHarness(viewModel: vm, onResult: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escanear documento'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Escanear'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Escanear'))
          .onPressed,
      isNull,
    );
    expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
  });

  testWidgets('cancelar descarta la sesion actual y cierra el dialogo', (
    tester,
  ) async {
    var deletedSessions = 0;
    Object? dialogResult = const Object();
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-1' && request.method == 'DELETE') {
        deletedSessions += 1;
        return http.Response('', 204);
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': const [],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(jsonEncode(const []), 200);
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setLastKnownSessionId('s-1');
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-1',
        fileName: 'scan.pdf',
        bytes: [1, 2, 3],
        pageCount: 1,
        scannerName: 'Canon DR',
      ),
    );

    await tester.pumpWidget(
      buildDialogHarness(viewModel: vm, onResult: (value) => dialogResult = value),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(deletedSessions, 1);
    expect(dialogResult, isNull);
    expect(find.byType(ScanDocumentDialog), findsNothing);
  });

  testWidgets('usar escaneo devuelve el archivo actual y descarta la sesion local', (
    tester,
  ) async {
    var deletedSessions = 0;
    Object? dialogResult = const Object();
    final client = MockClient((request) async {
      if (request.url.path == '/api/scans/s-9' && request.method == 'DELETE') {
        deletedSessions += 1;
        return http.Response('', 204);
      }
      if (request.url.path == '/api/status') {
        return http.Response(
          jsonEncode({
            'application': 'windows-twain',
            'version': '1.0.0',
            'runMode': 'service',
            'operations': const [],
          }),
          200,
        );
      }
      if (request.url.path == '/api/sessions') {
        return http.Response(jsonEncode(const []), 200);
      }
      return http.Response('not-found', 404);
    });
    final vm = buildViewModel(client);
    vm.setServiceAvailable(true);
    vm.setSelectedScanner(buildScanner());
    vm.setLastKnownSessionId('s-9');
    vm.setLastScannedFile(
      const ScannedDocumentFile(
        sessionId: 's-9',
        fileName: 'scan-final.pdf',
        bytes: [7, 8, 9],
        pageCount: 2,
        scannerName: 'Canon DR',
      ),
    );

    await tester.pumpWidget(
      buildDialogHarness(viewModel: vm, onResult: (value) => dialogResult = value),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Usar escaneo'));
    await tester.tap(find.widgetWithText(FilledButton, 'Usar escaneo'));
    await tester.pumpAndSettle();

    expect(deletedSessions, 1);
    final result = dialogResult as ScannedDocumentFile;
    expect(result.sessionId, 's-9');
    expect(result.fileName, 'scan-final.pdf');
    expect(find.byType(ScanDocumentDialog), findsNothing);
  });
}

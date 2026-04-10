import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scan_session_details.dart';
import 'package:gdms_app/src/documents/presentation/scan_preview_section.dart';

void main() {
  Widget buildWidget({
    required ScannedDocumentFile scannedFile,
    required bool serviceAvailable,
    Future<void> Function()? onRefreshSessionRequested,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScanPreviewSection(
            scannedFile: scannedFile,
            previewBytes: null,
            serviceAvailable: serviceAvailable,
            currentPage: 1,
            sessionDetails: ScanSessionDetails(
              sessionId: 's-1',
              status: 'completed',
              mode: 'adf-duplex',
              pageCount: 3,
              scannerName: 'Canon DR',
              dpi: 300,
              pixelType: 'gray',
              discardBlankPages: 'auto',
            ),
            canShowPreviousPage: false,
            canShowNextPage: false,
            canDeleteCurrentPage: true,
            canRotateCurrentPage: true,
            canMoveCurrentPageBackward: false,
            canMoveCurrentPageForward: false,
            onPreviousPageRequested: () async {},
            onNextPageRequested: () async {},
            onRotateRequested: () async {},
            onDeleteRequested: () async {},
            onMoveBackwardRequested: () async {},
            onMoveForwardRequested: () async {},
            onAppendScanRequested: () async {},
            onInsertBeforeScanRequested: () async {},
            onInsertScanRequested: () async {},
            canAppendScan: true,
            canAdjustCurrentPage: true,
            onBrightenRequested: () async {},
            onDarkenRequested: () async {},
            onIncreaseContrastRequested: () async {},
            onDecreaseContrastRequested: () async {},
            canRefreshSession: true,
            onRefreshSessionRequested: onRefreshSessionRequested ?? () async {},
            onDiscardSessionRequested: () async {},
            onExportPdfRequested: () async => true,
            isBusy: false,
          ),
        ),
      ),
    );
  }

  testWidgets('cuando el host cae muestra retry guiado en la preview', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      buildWidget(
        scannedFile: const ScannedDocumentFile(
          sessionId: 's-1',
          fileName: 'scan.pdf',
          bytes: [1, 2, 3],
          pageCount: 3,
          scannerName: 'Canon DR',
        ),
        serviceAvailable: false,
        onRefreshSessionRequested: () async {
          retried = true;
        },
      ),
    );

    expect(find.text('Reintentar conexión'), findsOneWidget);
    expect(
      find.textContaining('Puedes reintentar la conexión'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar conexión'));
    await tester.pump();

    expect(retried, isTrue);
  });
}

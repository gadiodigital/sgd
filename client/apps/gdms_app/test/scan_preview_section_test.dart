import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scanned_document_file.dart';
import 'package:gdms_app/src/documents/domain/scan_session_details.dart';
import 'package:gdms_app/src/documents/presentation/scan_preview_section.dart';

void main() {
  const validPngBytes = <int>[
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    248,
    255,
    255,
    63,
    0,
    5,
    254,
    2,
    254,
    167,
    53,
    129,
    132,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ];

  Widget buildWidget({
    required ScannedDocumentFile scannedFile,
    List<int>? previewBytes,
    int currentPage = 1,
    ScanSessionDetails? sessionDetails,
    bool canShowPreviousPage = false,
    bool canShowNextPage = false,
    bool canDeleteCurrentPage = true,
    bool canRotateCurrentPage = true,
    bool canMoveCurrentPageBackward = false,
    bool canMoveCurrentPageForward = false,
    bool canAppendScan = true,
    bool canAdjustCurrentPage = true,
    bool canRefreshSession = true,
    bool isBusy = false,
    Future<void> Function()? onPreviousPageRequested,
    Future<void> Function()? onNextPageRequested,
    Future<void> Function()? onRotateRequested,
    Future<void> Function()? onDeleteRequested,
    Future<void> Function()? onMoveBackwardRequested,
    Future<void> Function()? onMoveForwardRequested,
    Future<void> Function()? onAppendScanRequested,
    Future<void> Function()? onInsertBeforeScanRequested,
    Future<void> Function()? onInsertScanRequested,
    Future<void> Function()? onBrightenRequested,
    Future<void> Function()? onDarkenRequested,
    Future<void> Function()? onIncreaseContrastRequested,
    Future<void> Function()? onDecreaseContrastRequested,
    Future<void> Function()? onRefreshSessionRequested,
    Future<void> Function()? onDiscardSessionRequested,
    Future<bool> Function()? onExportPdfRequested,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScanPreviewSection(
            scannedFile: scannedFile,
            previewBytes: previewBytes,
            currentPage: currentPage,
            sessionDetails: sessionDetails,
            canShowPreviousPage: canShowPreviousPage,
            canShowNextPage: canShowNextPage,
            canDeleteCurrentPage: canDeleteCurrentPage,
            canRotateCurrentPage: canRotateCurrentPage,
            canMoveCurrentPageBackward: canMoveCurrentPageBackward,
            canMoveCurrentPageForward: canMoveCurrentPageForward,
            onPreviousPageRequested:
                onPreviousPageRequested ?? () async {},
            onNextPageRequested: onNextPageRequested ?? () async {},
            onRotateRequested: onRotateRequested ?? () async {},
            onDeleteRequested: onDeleteRequested ?? () async {},
            onMoveBackwardRequested:
                onMoveBackwardRequested ?? () async {},
            onMoveForwardRequested:
                onMoveForwardRequested ?? () async {},
            onAppendScanRequested:
                onAppendScanRequested ?? () async {},
            onInsertBeforeScanRequested:
                onInsertBeforeScanRequested ?? () async {},
            onInsertScanRequested: onInsertScanRequested ?? () async {},
            canAppendScan: canAppendScan,
            canAdjustCurrentPage: canAdjustCurrentPage,
            onBrightenRequested: onBrightenRequested ?? () async {},
            onDarkenRequested: onDarkenRequested ?? () async {},
            onIncreaseContrastRequested:
                onIncreaseContrastRequested ?? () async {},
            onDecreaseContrastRequested:
                onDecreaseContrastRequested ?? () async {},
            canRefreshSession: canRefreshSession,
            onRefreshSessionRequested:
                onRefreshSessionRequested ?? () async {},
            onDiscardSessionRequested:
                onDiscardSessionRequested ?? () async {},
            onExportPdfRequested:
                onExportPdfRequested ?? () async => true,
            isBusy: isBusy,
          ),
        ),
      ),
    );
  }

  ScannedDocumentFile buildFile() {
    return const ScannedDocumentFile(
      sessionId: 's-1',
      fileName: 'scan.pdf',
      bytes: [1, 2, 3],
      pageCount: 3,
      scannerName: 'Canon DR',
    );
  }

  ScanSessionDetails buildDetails({
    String mode = 'adf-duplex',
    String status = 'completed',
    int? dpi = 300,
    String pixelType = 'gray',
    String discardBlankPages = 'auto',
  }) {
    return ScanSessionDetails(
      sessionId: 's-1',
      status: status,
      mode: mode,
      pageCount: 3,
      scannerName: 'Canon DR',
      dpi: dpi,
      pixelType: pixelType,
      discardBlankPages: discardBlankPages,
    );
  }

  testWidgets('renderiza preview ADF con metadata y acciones principales', (
    tester,
  ) async {
    var exported = false;
    var refreshed = false;
    var appended = false;

    await tester.pumpWidget(
      buildWidget(
        scannedFile: buildFile(),
        previewBytes: Uint8List.fromList(validPngBytes),
        currentPage: 2,
        sessionDetails: buildDetails(),
        canShowPreviousPage: true,
        canShowNextPage: true,
        canMoveCurrentPageBackward: true,
        canMoveCurrentPageForward: true,
        onExportPdfRequested: () async {
          exported = true;
          return true;
        },
        onRefreshSessionRequested: () async {
          refreshed = true;
        },
        onAppendScanRequested: () async {
          appended = true;
        },
      ),
    );

    expect(find.text('Previsualizacion'), findsOneWidget);
    expect(find.text('scan.pdf · pagina 2 de 3 · Canon DR'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Sesion s-1 · adf-duplex · completed'), findsOneWidget);
    expect(find.text('DPI 300 · gray · blancas auto'), findsOneWidget);
    expect(find.text('Agregar paginas'), findsOneWidget);
    expect(find.text('Insertar antes'), findsOneWidget);
    expect(find.text('Insertar despues'), findsOneWidget);

    await tester.ensureVisible(find.text('Exportar PDF'));
    await tester.tap(find.text('Exportar PDF'));
    await tester.pump();
    await tester.tap(find.text('Releer sesión'));
    await tester.pump();
    await tester.tap(find.text('Agregar paginas'));
    await tester.pump();

    expect(exported, isTrue);
    expect(refreshed, isTrue);
    expect(appended, isTrue);
  });

  testWidgets('adapta labels y helper para sesiones flatbed', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        scannedFile: buildFile(),
        previewBytes: null,
        sessionDetails: buildDetails(mode: 'flatbed-single'),
      ),
    );

    expect(
      find.text(
        'No se pudo generar la preview, pero el PDF escaneado quedo disponible.',
      ),
      findsOneWidget,
    );
    expect(find.text('Agregar hoja'), findsOneWidget);
    expect(find.text('Insertar hoja antes'), findsOneWidget);
    expect(find.text('Insertar hoja despues'), findsOneWidget);
    expect(
      find.textContaining('sumar nuevas hojas desde cama plana'),
      findsOneWidget,
    );
  });

  testWidgets('en busy deshabilita todas las acciones operativas', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        scannedFile: buildFile(),
        sessionDetails: buildDetails(),
        isBusy: true,
      ),
    );

    final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });
}

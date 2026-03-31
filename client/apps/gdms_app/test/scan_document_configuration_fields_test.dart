import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/domain/windows_twain_service_status.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_configuration_fields.dart';

void main() {
  Widget buildWidget({
    ScanSource source = ScanSource.adf,
    List<ScannerDevice> scanners = const [],
    ScannerDevice? selectedScanner,
    bool isBusy = false,
    bool canUseAdf = true,
    bool canScanFlatbed = true,
    bool canScanSimplex = true,
    bool canScanDuplex = true,
    bool duplex = false,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    WindowsTwainServiceStatus? serviceStatus,
    ValueChanged<ScanSource>? onSourceChanged,
    ValueChanged<ScannerDevice?>? onScannerChanged,
    ValueChanged<bool>? onDuplexChanged,
    ValueChanged<int>? onDpiChanged,
    ValueChanged<String>? onPixelTypeChanged,
    ValueChanged<String>? onDiscardBlankPagesChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScanDocumentConfigurationFields(
            source: source,
            scanners: scanners,
            selectedScanner: selectedScanner,
            isBusy: isBusy,
            canUseAdf: canUseAdf,
            canScanFlatbed: canScanFlatbed,
            canScanSimplex: canScanSimplex,
            canScanDuplex: canScanDuplex,
            duplex: duplex,
            dpi: dpi,
            pixelType: pixelType,
            discardBlankPages: discardBlankPages,
            serviceStatus: serviceStatus,
            onSourceChanged: onSourceChanged ?? (_) {},
            onScannerChanged: onScannerChanged ?? (_) {},
            onDuplexChanged: onDuplexChanged ?? (_) {},
            onDpiChanged: onDpiChanged ?? (_) {},
            onPixelTypeChanged: onPixelTypeChanged ?? (_) {},
            onDiscardBlankPagesChanged:
                onDiscardBlankPagesChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  ScannerDevice buildScanner({
    int? id = 5,
    String name = 'fi-8170',
    String manufacturer = 'Fujitsu',
    String productFamily = 'ScanSnap',
    String twainVersion = '2.4',
    bool isOpen = false,
  }) {
    return ScannerDevice(
      id: id,
      name: name,
      manufacturer: manufacturer,
      productFamily: productFamily,
      twainVersion: twainVersion,
      isOpen: isOpen,
    );
  }

  WindowsTwainServiceStatus buildServiceStatus({
    List<String> operations = const ['scan-adf-duplex'],
  }) {
    return WindowsTwainServiceStatus(
      application: 'windows-twain',
      version: '1.0.0',
      baseUrl: 'http://127.0.0.1:43127',
      runMode: 'service',
      startupLogPath: '',
      scannerSummary: '',
      activeSessions: 0,
      sessionsRootPath: '',
      lastCleanupAtUtc: null,
      lastCleanupDeletedCount: 0,
      operations: operations,
    );
  }

  testWidgets('renderiza campos ADF con scanner seleccionado y soporte duplex', (
    tester,
  ) async {
    final scanner = buildScanner();

    await tester.pumpWidget(
      buildWidget(
        source: ScanSource.adf,
        scanners: [scanner],
        selectedScanner: scanner,
        duplex: true,
        serviceStatus: buildServiceStatus(),
      ),
    );

    expect(find.text('ADF'), findsOneWidget);
    expect(find.text('Cama plana'), findsOneWidget);
    expect(find.text('Simplex'), findsOneWidget);
    expect(find.text('Duplex'), findsOneWidget);
    expect(find.text('Escaneres detectados: 1'), findsOneWidget);
    expect(find.text('Fujitsu fi-8170'), findsOneWidget);
    expect(find.text('Paginas en blanco'), findsOneWidget);
    expect(
      find.text('El host actual no publica soporte para escaneo duplex.'),
      findsNothing,
    );
  });

  testWidgets('renderiza modo flatbed y advertencia cuando no hay scanners', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        source: ScanSource.flatbed,
        scanners: const [],
        selectedScanner: null,
      ),
    );

    expect(
      find.text(
        'Cama plana captura una sola pagina por disparo y no usa duplex.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'No hay escaneres detectados. Verifica drivers TWAIN, ADF cargado y arquitectura compatible.',
      ),
      findsOneWidget,
    );
    expect(find.text('Paginas en blanco'), findsNothing);
    expect(find.text('Simplex'), findsNothing);
    expect(find.text('Duplex'), findsNothing);
  });

  testWidgets('dispara callbacks de source, scanner y dropdowns', (
    tester,
  ) async {
    final scanner = buildScanner();
    ScanSource? selectedSource;
    ScannerDevice? selectedScanner;
    bool? selectedDuplex;
    int? selectedDpi;
    String? selectedPixelType;
    String? selectedBlankMode;

    await tester.pumpWidget(
      buildWidget(
        source: ScanSource.adf,
        scanners: [scanner],
        selectedScanner: scanner,
        onSourceChanged: (value) => selectedSource = value,
        onScannerChanged: (value) => selectedScanner = value,
        onDuplexChanged: (value) => selectedDuplex = value,
        onDpiChanged: (value) => selectedDpi = value,
        onPixelTypeChanged: (value) => selectedPixelType = value,
        onDiscardBlankPagesChanged: (value) => selectedBlankMode = value,
      ),
    );

    final sourceButton = tester.widget<SegmentedButton<ScanSource>>(
      find.byType(SegmentedButton<ScanSource>).first,
    );
    sourceButton.onSelectionChanged!({ScanSource.flatbed});

    final duplexButton = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>),
    );
    duplexButton.onSelectionChanged!({true});

    final scannerField = tester.widget<DropdownButtonFormField<ScannerDevice>>(
      find.byType(DropdownButtonFormField<ScannerDevice>),
    );
    scannerField.onChanged!.call(scanner);

    final dpiField = tester.widgetList<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    ).single;
    dpiField.onChanged!.call(400);

    final pixelTypeField = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    ).first;
    pixelTypeField.onChanged!.call('gray');

    final blankField = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    ).last;
    blankField.onChanged!.call('off');

    expect(selectedSource, ScanSource.flatbed);
    expect(selectedScanner, scanner);
    expect(selectedDuplex, isTrue);
    expect(selectedDpi, 400);
    expect(selectedPixelType, 'gray');
    expect(selectedBlankMode, 'off');
  });

  testWidgets('en busy deshabilita segmented buttons y dropdowns', (
    tester,
  ) async {
    final scanner = buildScanner();

    await tester.pumpWidget(
      buildWidget(
        source: ScanSource.adf,
        scanners: [scanner],
        selectedScanner: scanner,
        isBusy: true,
      ),
    );

    final sourceButton = tester.widget<SegmentedButton<ScanSource>>(
      find.byType(SegmentedButton<ScanSource>).first,
    );
    final duplexButton = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>),
    );
    final scannerField = tester.widget<DropdownButtonFormField<ScannerDevice>>(
      find.byType(DropdownButtonFormField<ScannerDevice>),
    );
    final dpiField = tester.widgetList<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    ).single;
    final stringFields = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );

    expect(sourceButton.onSelectionChanged, isNull);
    expect(duplexButton.onSelectionChanged, isNull);
    expect(scannerField.onChanged, isNull);
    expect(dpiField.onChanged, isNull);
    expect(stringFields.every((field) => field.onChanged == null), isTrue);
  });

  testWidgets('avisa cuando el host no publica soporte duplex', (tester) async {
    final scanner = buildScanner();

    await tester.pumpWidget(
      buildWidget(
        source: ScanSource.adf,
        scanners: [scanner],
        selectedScanner: scanner,
        serviceStatus: buildServiceStatus(operations: const ['scan-adf-simplex']),
      ),
    );

    expect(
      find.text('El host actual no publica soporte para escaneo duplex.'),
      findsOneWidget,
    );
  });
}

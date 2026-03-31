import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scan_source.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_effective_summary.dart';

void main() {
  Widget buildWidget({
    ScannerDevice? selectedScanner,
    ScanSource source = ScanSource.adf,
    bool duplex = false,
    int dpi = 300,
    String pixelType = 'color',
    String discardBlankPages = 'auto',
    bool canScan = true,
    String readinessReason = 'Selecciona un escaner',
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentEffectiveSummary(
          selectedScanner: selectedScanner,
          source: source,
          duplex: duplex,
          dpi: dpi,
          pixelType: pixelType,
          discardBlankPages: discardBlankPages,
          canScan: canScan,
          readinessReason: readinessReason,
        ),
      ),
    );
  }

  ScannerDevice buildScanner({
    String name = 'fi-8170',
    String manufacturer = 'Fujitsu',
  }) {
    return ScannerDevice(
      id: 3,
      name: name,
      manufacturer: manufacturer,
      productFamily: 'ScanSnap',
      twainVersion: '2.4',
      isOpen: false,
    );
  }

  testWidgets('resume configuracion ADF lista para escanear', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        selectedScanner: buildScanner(),
        source: ScanSource.adf,
        duplex: true,
        dpi: 300,
        pixelType: 'gray',
        discardBlankPages: 'auto',
        canScan: true,
      ),
    );

    expect(find.text('Configuracion efectiva'), findsOneWidget);
    expect(find.text('Fujitsu fi-8170 · duplex · 300 dpi'), findsOneWidget);
    expect(find.text('Listo para escanear'), findsOneWidget);
    expect(find.text('Escala de grises'), findsOneWidget);
    expect(find.text('Descarta blancas'), findsOneWidget);
  });

  testWidgets('resume configuracion ADF simplex con blanco y negro', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        selectedScanner: buildScanner(),
        source: ScanSource.adf,
        duplex: false,
        dpi: 200,
        pixelType: 'bw',
        discardBlankPages: 'off',
        canScan: true,
      ),
    );

    expect(find.text('Fujitsu fi-8170 · simplex · 200 dpi'), findsOneWidget);
    expect(find.text('Blanco y negro'), findsOneWidget);
    expect(find.text('Conserva blancas'), findsOneWidget);
  });

  testWidgets('resume configuracion flatbed con fallback de scanner y color', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        selectedScanner: null,
        source: ScanSource.flatbed,
        duplex: false,
        dpi: 150,
        pixelType: 'color',
        discardBlankPages: 'auto',
        canScan: true,
      ),
    );

    expect(find.text('Sin escaner · cama plana · 150 dpi'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);
    expect(find.text('Una pagina'), findsOneWidget);
  });

  testWidgets('muestra razon critica cuando no puede escanear', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        selectedScanner: buildScanner(),
        source: ScanSource.adf,
        duplex: true,
        canScan: false,
        readinessReason: 'El host no soporta duplex',
      ),
    );

    expect(find.text('El host no soporta duplex'), findsOneWidget);
    expect(find.text('Listo para escanear'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_readiness_checklist.dart';

void main() {
  Widget buildWidget({
    String sourceLabel = 'ADF',
    bool serviceAvailable = true,
    bool hasScanners = true,
    bool hasSelectedScanner = true,
    bool modeSupported = true,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentReadinessChecklist(
          sourceLabel: sourceLabel,
          serviceAvailable: serviceAvailable,
          hasScanners: hasScanners,
          hasSelectedScanner: hasSelectedScanner,
          modeSupported: modeSupported,
        ),
      ),
    );
  }

  testWidgets('muestra checklist completa en estado listo', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        sourceLabel: 'ADF duplex',
        serviceAvailable: true,
        hasScanners: true,
        hasSelectedScanner: true,
        modeSupported: true,
      ),
    );

    expect(find.text('Checklist previa'), findsOneWidget);
    expect(
      find.text(
        'Antes de escanear, confirma estos cuatro puntos para ADF duplex.',
      ),
      findsOneWidget,
    );
    expect(find.text('Servicio local OK'), findsOneWidget);
    expect(find.text('Scanner detectado OK'), findsOneWidget);
    expect(find.text('Scanner seleccionado OK'), findsOneWidget);
    expect(find.text('Modo compatible OK'), findsOneWidget);
  });

  testWidgets('muestra items pendientes cuando faltan prerequisitos', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        sourceLabel: 'cama plana',
        serviceAvailable: false,
        hasScanners: false,
        hasSelectedScanner: false,
        modeSupported: false,
      ),
    );

    expect(
      find.text(
        'Antes de escanear, confirma estos cuatro puntos para cama plana.',
      ),
      findsOneWidget,
    );
    expect(find.text('Servicio local pendiente'), findsOneWidget);
    expect(find.text('Scanner detectado pendiente'), findsOneWidget);
    expect(find.text('Scanner seleccionado pendiente'), findsOneWidget);
    expect(find.text('Modo compatible pendiente'), findsOneWidget);
  });

  testWidgets('mezcla estados OK y pendientes segun cada señal', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        serviceAvailable: true,
        hasScanners: false,
        hasSelectedScanner: true,
        modeSupported: false,
      ),
    );

    expect(find.text('Servicio local OK'), findsOneWidget);
    expect(find.text('Scanner detectado pendiente'), findsOneWidget);
    expect(find.text('Scanner seleccionado OK'), findsOneWidget);
    expect(find.text('Modo compatible pendiente'), findsOneWidget);
  });
}

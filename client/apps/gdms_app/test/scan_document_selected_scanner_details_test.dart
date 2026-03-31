import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/domain/scanner_device.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_selected_scanner_details.dart';

void main() {
  Widget buildWidget(ScannerDevice scanner) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentSelectedScannerDetails(scanner: scanner),
      ),
    );
  }

  ScannerDevice buildScanner({
    int? id = 7,
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

  testWidgets('renderiza badges completos cuando el scanner esta sano', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget(buildScanner()));

    expect(find.text('Source #7'), findsOneWidget);
    expect(find.text('Fujitsu'), findsOneWidget);
    expect(find.text('ScanSnap'), findsOneWidget);
    expect(find.text('TWAIN 2.4'), findsOneWidget);
    expect(find.text('Source cerrado'), findsOneWidget);
    expect(find.text('Compatibilidad TWAIN OK'), findsOneWidget);
    expect(find.textContaining('Cierra otras aplicaciones de escaneo'), findsNothing);
    expect(find.textContaining('Faltan metadatos TWAIN'), findsNothing);
  });

  testWidgets('muestra consejo operativo cuando el source aparece abierto', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        buildScanner(
          isOpen: true,
        ),
      ),
    );

    expect(find.text('Source abierto'), findsOneWidget);
    expect(
      find.text(
        'El source aparece abierto. Cierra otras aplicaciones de escaneo antes de capturar.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('usa fallbacks y consejo de driver cuando faltan metadatos', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        buildScanner(
          id: null,
          manufacturer: '',
          productFamily: '',
          twainVersion: '',
        ),
      ),
    );

    expect(find.text('Source sin id'), findsOneWidget);
    expect(find.text('Fabricante sin dato'), findsOneWidget);
    expect(find.text('Familia sin dato'), findsOneWidget);
    expect(find.text('TWAIN sin dato'), findsOneWidget);
    expect(find.text('Verificar driver TWAIN'), findsOneWidget);
    expect(
      find.text(
        'Faltan metadatos TWAIN. Conviene revisar o reinstalar el driver del escaner.',
      ),
      findsOneWidget,
    );
  });
}

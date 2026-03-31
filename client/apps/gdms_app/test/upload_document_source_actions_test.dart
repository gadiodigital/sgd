import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/upload_document_source_actions.dart';

void main() {
  Widget buildActions({
    PlatformFile? selectedFile,
    bool isBusy = false,
    bool supportsScannerIntegration = true,
    Future<void> Function()? onPickFile,
    Future<void> Function()? onScanDocument,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: UploadDocumentSourceActions(
          selectedFile: selectedFile,
          isBusy: isBusy,
          supportsScannerIntegration: supportsScannerIntegration,
          onPickFile: onPickFile ?? () async {},
          onScanDocument: onScanDocument ?? () async {},
        ),
      ),
    );
  }

  testWidgets('renderiza acciones base y dispara callbacks', (tester) async {
    var pickCalls = 0;
    var scanCalls = 0;

    await tester.pumpWidget(
      buildActions(
        onPickFile: () async => pickCalls += 1,
        onScanDocument: () async => scanCalls += 1,
      ),
    );

    expect(find.text('Seleccionar archivo'), findsOneWidget);
    expect(find.text('Escanear documento'), findsOneWidget);

    await tester.tap(find.text('Seleccionar archivo'));
    await tester.pump();
    await tester.tap(find.text('Escanear documento'));
    await tester.pump();

    expect(pickCalls, 1);
    expect(scanCalls, 1);
  });

  testWidgets('muestra el nombre del archivo seleccionado y oculta escaneo si no aplica', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildActions(
        selectedFile: PlatformFile(name: 'contrato.pdf', size: 4),
        supportsScannerIntegration: false,
      ),
    );

    expect(find.text('contrato.pdf'), findsOneWidget);
    expect(find.text('Escanear documento'), findsNothing);
  });

  testWidgets('deshabilita ambas acciones en busy', (tester) async {
    await tester.pumpWidget(buildActions(isBusy: true));

    final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    for (final button in buttons) {
      expect(button.onPressed, isNull);
    }
  });
}

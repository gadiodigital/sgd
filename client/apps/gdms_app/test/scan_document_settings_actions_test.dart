import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdms_app/src/documents/presentation/scan_document_settings_actions.dart';

void main() {
  Widget buildWidget({
    bool isBusy = false,
    bool hasSelectedScanner = true,
    VoidCallback? onResetRequested,
    VoidCallback? onForgetScannerRequested,
  }) {
    return MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: Scaffold(
        body: ScanDocumentSettingsActions(
          isBusy: isBusy,
          hasSelectedScanner: hasSelectedScanner,
          onResetRequested: onResetRequested ?? () {},
          onForgetScannerRequested: onForgetScannerRequested ?? () {},
        ),
      ),
    );
  }

  testWidgets('renderiza ambas acciones y dispara callbacks', (tester) async {
    var reset = false;
    var forget = false;

    await tester.pumpWidget(
      buildWidget(
        onResetRequested: () => reset = true,
        onForgetScannerRequested: () => forget = true,
      ),
    );

    expect(find.text('Restaurar defaults'), findsOneWidget);
    expect(find.text('Olvidar scanner'), findsOneWidget);

    await tester.tap(find.text('Restaurar defaults'));
    await tester.pump();
    await tester.tap(find.text('Olvidar scanner'));
    await tester.pump();

    expect(reset, isTrue);
    expect(forget, isTrue);
  });

  testWidgets('deshabilita olvidar scanner cuando no hay scanner seleccionado', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        hasSelectedScanner: false,
      ),
    );

    final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton)).toList();
    expect(buttons[0].onPressed, isNotNull);
    expect(buttons[1].onPressed, isNull);
  });

  testWidgets('en busy deshabilita ambas acciones', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        isBusy: true,
      ),
    );

    final buttons = tester.widgetList<OutlinedButton>(find.byType(OutlinedButton));
    expect(buttons.every((button) => button.onPressed == null), isTrue);
  });
}
